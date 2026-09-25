using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.RequestOtp;

internal sealed class RequestOtpCommandHandler(
    IOtpChallengeRepository otpChallenges,
    IOtpCodeGenerator otpCodeGenerator,
    IOtpSender otpSender,
    TimeProvider timeProvider)
    : ICommandHandler<RequestOtpCommand, RequestOtpResponse>
{
    public async Task<Result<RequestOtpResponse>> Handle(RequestOtpCommand request, CancellationToken cancellationToken)
    {
        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<RequestOtpResponse>(phoneResult.Error);
        }

        var phone = phoneResult.Value;
        var now = timeProvider.GetUtcNow();

        var latest = await otpChallenges.GetLatestForPhoneAsync(phone, cancellationToken);
        if (latest is not null && latest.IsActive(now) && now - latest.CreatedAtUtc < OtpChallenge.ResendCooldown)
        {
            var retryAfterSeconds = (int)Math.Ceiling((OtpChallenge.ResendCooldown - (now - latest.CreatedAtUtc)).TotalSeconds);
            return Error.BusinessRule(
                "Otp.ResendTooSoon",
                $"A code was already sent. Please wait {retryAfterSeconds} seconds before requesting another.");
        }

        var code = otpCodeGenerator.GenerateCode();
        var codeHash = otpCodeGenerator.Hash(phone.Value, code);
        var challenge = OtpChallenge.Issue(phone, codeHash, now);
        otpChallenges.Add(challenge);

        await otpSender.SendAsync(phone, code, cancellationToken);

        return new RequestOtpResponse(challenge.ExpiresAtUtc, (int)OtpChallenge.ResendCooldown.TotalSeconds);
    }
}
