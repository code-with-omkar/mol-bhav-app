using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.VerifyOtp;

internal sealed class VerifyOtpCommandHandler(
    ILoginMethods loginMethods,
    IOtpChallengeRepository otpChallenges,
    IUserRepository users,
    IRefreshTokenRepository refreshTokens,
    IOtpCodeGenerator otpCodeGenerator,
    IJwtTokenService jwtTokenService,
    TimeProvider timeProvider)
    : ICommandHandler<VerifyOtpCommand, VerifyOtpResponse>
{
    public async Task<Result<VerifyOtpResponse>> Handle(VerifyOtpCommand request, CancellationToken cancellationToken)
    {
        // OTP costs money per SMS; deployments without a DLT-registered sender switch it off (Authentication:LoginMethods:Otp).
        if (!loginMethods.OtpEnabled)
        {
            return IdentityErrors.LoginMethodDisabled;
        }

        var phoneResult = PhoneNumber.Create(request.PhoneNumber);
        if (phoneResult.IsFailure)
        {
            return Result.Failure<VerifyOtpResponse>(phoneResult.Error);
        }

        var phone = phoneResult.Value;
        var now = timeProvider.GetUtcNow();

        var challenge = await otpChallenges.GetLatestForPhoneAsync(phone, cancellationToken);
        if (challenge is null)
        {
            return Error.Validation("Otp.ChallengeNotFound", "Request a new verification code.");
        }

        var presentedHash = otpCodeGenerator.Hash(phone.Value, request.Code);
        var outcome = challenge.Verify(presentedHash, now);

        // Every non-null branch below is Result.Success even when Outcome != Verified: a wrong/expired/exhausted
        // attempt still increments OtpChallenge.AttemptCount, and that must be persisted for the attempt limit to
        // mean anything. UnitOfWorkBehavior commits only on Result.Success — but EF Core only emits an UPDATE for
        // properties that actually changed, so committing here is harmless on the (rare) branches where nothing
        // in fact changed (e.g. an already-expired challenge). The controller maps Outcome to the HTTP status.
        if (outcome != OtpVerificationOutcome.Verified)
        {
            return new VerifyOtpResponse(outcome, null, null, null, null, null, IsNewUser: false, IsOnboarded: false);
        }

        var user = await users.GetByPhoneNumberAsync(phone, cancellationToken);
        var isNewUser = user is null;

        if (user is null)
        {
            user = User.Register(phone);
            users.Add(user);
        }
        else if (user.Status != UserStatus.Active)
        {
            // Rolling back the consumed challenge here is harmless: the code was correct, the account simply may not log in.
            return Error.Forbidden("User.Suspended", "This account has been suspended. Contact support.");
        }

        user.RecordLogin(now);

        var accessToken = jwtTokenService.CreateAccessToken(TokenSubjects.For(user));

        var refreshToken = jwtTokenService.CreateRefreshToken();
        var grant = RefreshTokenGrant.IssueInitial(user.Id, refreshToken.TokenHash, refreshToken.ExpiresAtUtc);
        refreshTokens.Add(grant);

        return new VerifyOtpResponse(
            OtpVerificationOutcome.Verified,
            user.Id,
            accessToken.Token,
            accessToken.ExpiresAtUtc,
            refreshToken.Token,
            refreshToken.ExpiresAtUtc,
            isNewUser,
            user.IsOnboarded);
    }
}
