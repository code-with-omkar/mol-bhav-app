using FluentValidation;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.ResetPassword;

/// <summary>Whether the code was right; the password changes only when <see cref="Outcome"/> is verified.</summary>
public sealed record ResetPasswordResponse(OtpVerificationOutcome Outcome);

/// <summary>"Forgot password", step two: the code from the phone plus the new password.</summary>
public sealed record ResetPasswordCommand(string PhoneNumber, string Code, string NewPassword) : ICommand<ResetPasswordResponse>;

internal sealed class ResetPasswordCommandValidator : AbstractValidator<ResetPasswordCommand>
{
    public ResetPasswordCommandValidator()
    {
        RuleFor(x => x.PhoneNumber).NotEmpty().MaximumLength(20);
        RuleFor(x => x.Code).NotEmpty().MaximumLength(10);
        RuleFor(x => x.NewPassword).NewPassword();
    }
}

internal sealed class ResetPasswordCommandHandler(
    ILoginMethods loginMethods,
    IPasswordResetCodeSender sender,
    IUserRepository users,
    IOtpChallengeRepository otpChallenges,
    IOtpCodeGenerator otpCodeGenerator,
    IPasswordHasher passwordHasher,
    IRefreshTokenRepository refreshTokens,
    TimeProvider timeProvider)
    : ICommandHandler<ResetPasswordCommand, ResetPasswordResponse>
{
    public async Task<Result<ResetPasswordResponse>> Handle(ResetPasswordCommand request, CancellationToken cancellationToken)
    {
        if (!loginMethods.PasswordEnabled || !sender.IsEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<ResetPasswordResponse>(phoneResult.Error);
        }

        var phone = phoneResult.Value;
        var now = timeProvider.GetUtcNow();

        var challenge = await otpChallenges.GetLatestForPhoneAsync(phone, cancellationToken);
        if (challenge is null)
        {
            return Error.Validation("Otp.ChallengeNotFound", "Request a new verification code.");
        }

        // A wrong attempt is still a committed success, so the attempt limit is saved (as in VerifyOtp).
        var outcome = challenge.Verify(otpCodeGenerator.Hash(phone.Value, request.Code), now);
        if (outcome != OtpVerificationOutcome.Verified)
        {
            return new ResetPasswordResponse(outcome);
        }

        var user = await users.GetByPhoneNumberAsync(phone, cancellationToken);
        if (user is null)
        {
            // No code is ever sent to a number without an account, so a "right" code here proves nothing.
            return new ResetPasswordResponse(OtpVerificationOutcome.IncorrectCode);
        }

        if (user.Status != UserStatus.Active)
        {
            return Error.Forbidden("User.Suspended", "This account has been suspended. Contact support.");
        }

        user.SetPassword(passwordHasher.Hash(request.NewPassword));

        // Whoever held the old password or an old session is signed out.
        foreach (var grant in await refreshTokens.GetActiveForUserAsync(user.Id, cancellationToken))
        {
            grant.Revoke(now);
        }

        return new ResetPasswordResponse(outcome);
    }
}
