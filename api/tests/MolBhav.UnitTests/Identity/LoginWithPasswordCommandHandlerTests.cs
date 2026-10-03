using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Features.Identity.PasswordLogin;
using MolBhav.Domain.Identity;
using static MolBhav.UnitTests.Identity.PasswordLoginTestContext;

namespace MolBhav.UnitTests.Identity;

public sealed class LoginWithPasswordCommandHandlerTests
{
    private readonly PasswordLoginTestContext _ctx = new();

    private LoginWithPasswordCommandHandler CreateHandler() =>
        new(_ctx.LoginMethods, _ctx.Users, _ctx.RefreshTokens, _ctx.Hasher, _ctx.Jwt, _ctx.Clock);

    private Task<MolBhav.Domain.Common.Results.Result<PasswordLoginResponse>> Login(string password) =>
        CreateHandler().Handle(new LoginWithPasswordCommand(Phone, password), CancellationToken.None);

    [Fact]
    public async Task Handle_CorrectPassword_IssuesSessionAndRecordsLogin()
    {
        var user = _ctx.ExistingUser();

        var result = await Login(Password);

        Assert.True(result.IsSuccess);
        Assert.Equal(PasswordLoginOutcome.Succeeded, result.Value.Outcome);
        Assert.Equal("access", result.Value.Session!.AccessToken);
        Assert.False(result.Value.Session.IsNewUser);
        Assert.Equal(Now, user.LastLoginAtUtc);
        _ctx.RefreshTokens.Received(1).Add(Arg.Any<RefreshTokenGrant>());
    }

    [Fact]
    public async Task Handle_WrongPassword_ReturnsInvalidCredentialsAndCountsTheAttempt()
    {
        var user = _ctx.ExistingUser();

        var result = await Login("wrong-pass1");

        Assert.True(result.IsSuccess); // committed, so the counter persists
        Assert.Equal(PasswordLoginOutcome.InvalidCredentials, result.Value.Outcome);
        Assert.Null(result.Value.Session);
        Assert.Equal(1, user.FailedPasswordAttempts);
        _ctx.RefreshTokens.DidNotReceive().Add(Arg.Any<RefreshTokenGrant>());
    }

    [Fact]
    public async Task Handle_FifthWrongPassword_LocksTheAccount()
    {
        var user = _ctx.ExistingUser();
        for (var i = 1; i < User.MaxFailedPasswordAttempts; i++)
        {
            user.RecordFailedPasswordAttempt(Now);
        }

        var result = await Login("wrong-pass1");

        Assert.Equal(PasswordLoginOutcome.LockedOut, result.Value.Outcome);
        Assert.Equal(Now.Add(User.PasswordLockoutDuration), result.Value.LockedUntilUtc);
    }

    [Fact]
    public async Task Handle_LockedAccount_RefusesEvenTheCorrectPassword()
    {
        var user = _ctx.ExistingUser();
        for (var i = 0; i < User.MaxFailedPasswordAttempts; i++)
        {
            user.RecordFailedPasswordAttempt(Now.AddMinutes(-1));
        }

        var result = await Login(Password);

        Assert.Equal(PasswordLoginOutcome.LockedOut, result.Value.Outcome);
        _ctx.Hasher.DidNotReceive().Verify(Arg.Any<string?>(), Arg.Any<string>());
    }

    [Fact]
    public async Task Handle_UnknownNumber_ReturnsInvalidCredentialsAfterAFullCostHash()
    {
        var result = await Login(Password);

        Assert.Equal(PasswordLoginOutcome.InvalidCredentials, result.Value.Outcome);
        _ctx.Hasher.Received(1).Verify(null, Password);
    }

    [Fact]
    public async Task Handle_OtpOnlyAccount_ReturnsInvalidCredentialsWithoutCountingAttempts()
    {
        var user = _ctx.ExistingUser(password: null);

        var result = await Login(Password);

        Assert.Equal(PasswordLoginOutcome.InvalidCredentials, result.Value.Outcome);
        Assert.Equal(0, user.FailedPasswordAttempts);
    }

    [Fact]
    public async Task Handle_OutdatedHash_IsUpgradedOnSuccess()
    {
        var user = _ctx.ExistingUser();
        _ctx.Hasher.Verify(Arg.Any<string?>(), Arg.Any<string>()).Returns(PasswordVerificationResult.SuccessRehashNeeded);
        _ctx.Hasher.Hash(Password).Returns("hash:v2");

        var result = await Login(Password);

        Assert.Equal(PasswordLoginOutcome.Succeeded, result.Value.Outcome);
        Assert.Equal("hash:v2", user.PasswordHash);
    }

    [Fact]
    public async Task Handle_PasswordLoginDisabled_FailsWithMethodDisabled()
    {
        _ctx.LoginMethods.PasswordEnabled.Returns(false);

        var result = await Login(Password);

        Assert.True(result.IsFailure);
        Assert.Equal("Auth.MethodDisabled", result.Error.Code);
    }
}
