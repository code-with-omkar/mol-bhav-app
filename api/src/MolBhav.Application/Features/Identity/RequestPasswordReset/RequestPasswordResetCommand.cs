using FluentValidation;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.RequestPasswordReset;

public sealed record PasswordResetRequestedResponse(DateTimeOffset ExpiresAtUtc, int ResendCooldownSeconds);

/// <summary>"Forgot password": sends a code to the mobile number, if it has an active account.</summary>
public sealed record RequestPasswordResetCommand(string PhoneNumber) : ICommand<PasswordResetRequestedResponse>;

internal sealed class RequestPasswordResetCommandValidator : AbstractValidator<RequestPasswordResetCommand>
{
    public RequestPasswordResetCommandValidator()
    {
        RuleFor(x => x.PhoneNumber).NotEmpty().MaximumLength(20);
    }
}

internal sealed class RequestPasswordResetCommandHandler(
    ILoginMethods loginMethods,
    IPasswordResetCodeSender sender,
    IUserRepository users,
    IOtpChallengeRepository otpChallenges,
    IOtpCodeGenerator otpCodeGenerator,
    TimeProvider timeProvider)
    : ICommandHandler<RequestPasswordResetCommand, PasswordResetRequestedResponse>
{
    public async Task<Result<PasswordResetRequestedResponse>> Handle(RequestPasswordResetCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.PasswordEnabled || !sender.IsEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<PasswordResetRequestedResponse>(phoneResult.Error);
        }

        var phone = phoneResult.Value;
        var now = timeProvider.GetUtcNow();
        var cooldownSeconds = (int)OtpChallenge.ResendCooldown.TotalSeconds;

        var latest = await otpChallenges.GetLatestForPhoneAsync(phone, cancellationToken);
        if (latest is not null && latest.IsActive(now) && now - latest.CreatedAtUtc < OtpChallenge.ResendCooldown)
        {
            var wait = (int)Math.Ceiling((OtpChallenge.ResendCooldown - (now - latest.CreatedAtUtc)).TotalSeconds);
            return Error.BusinessRule("Otp.ResendTooSoon", $"A code was already sent. Please wait {wait} seconds before requesting another.");
        }

        // A challenge is stored for any valid number, so every answer (and the cooldown) looks the same whether or not an
        // account exists. The code is sent only to an account that can use it.
        var code = otpCodeGenerator.GenerateCode();
        var challenge = OtpChallenge.Issue(phone, otpCodeGenerator.Hash(phone.Value, code), now);
        otpChallenges.Add(challenge);

        var user = await users.GetByPhoneNumberAsync(phone, cancellationToken);
        if (user is { Status: UserStatus.Active })
        {
            await sender.SendAsync(phone, code, cancellationToken);
        }

        return new PasswordResetRequestedResponse(challenge.ExpiresAtUtc, cooldownSeconds);
    }
}
