using MolBhav.Application.Features.Identity.RegisterWithPassword;
using MolBhav.Domain.Identity;
using static MolBhav.UnitTests.Identity.PasswordLoginTestContext;

namespace MolBhav.UnitTests.Identity;

public sealed class RegisterWithPasswordCommandHandlerTests
{
    private readonly PasswordLoginTestContext _ctx = new();

    private Task<MolBhav.Domain.Common.Results.Result<MolBhav.Application.Features.Identity.LoginSessionResponse>> Register() =>
        new RegisterWithPasswordCommandHandler(_ctx.LoginMethods, _ctx.Users, _ctx.RefreshTokens, _ctx.Hasher, _ctx.Jwt, _ctx.Clock)
            .Handle(new RegisterWithPasswordCommand(Phone, Password), CancellationToken.None);

    [Fact]
    public async Task Handle_NewNumber_CreatesHashedAccountAndLogsIn()
    {
        User? added = null;
        _ctx.Users.When(u => u.Add(Arg.Any<User>())).Do(ci => added = ci.Arg<User>());

        var result = await Register();

        Assert.True(result.IsSuccess);
        Assert.True(result.Value.IsNewUser);
        Assert.False(result.Value.IsOnboarded);
        Assert.NotNull(added);
        Assert.Equal("hash:" + Password, added!.PasswordHash);
        Assert.Equal(Now, added.LastLoginAtUtc);
    }

    [Fact]
    public async Task Handle_NumberWithPassword_FailsWithAccountExists()
    {
        _ctx.ExistingUser();

        var result = await Register();

        Assert.True(result.IsFailure);
        Assert.Equal("Auth.AccountExists", result.Error.Code);
        _ctx.RefreshTokens.DidNotReceive().Add(Arg.Any<RefreshTokenGrant>());
    }

    [Fact]
    public async Task Handle_PasswordlessAccount_ClaimAllowed_SetsPasswordOnTheExistingAccount()
    {
        var user = _ctx.ExistingUser(password: null);
        _ctx.LoginMethods.AllowClaimingPasswordlessAccounts.Returns(true);

        var result = await Register();

        Assert.True(result.IsSuccess);
        Assert.False(result.Value.IsNewUser);
        Assert.Equal(user.Id, result.Value.UserId);
        Assert.Equal("hash:" + Password, user.PasswordHash);
        _ctx.Users.DidNotReceive().Add(Arg.Any<User>());
    }

    [Fact]
    public async Task Handle_PasswordlessAccount_ClaimNotAllowed_FailsWithAccountExists()
    {
        var user = _ctx.ExistingUser(password: null);

        var result = await Register();

        Assert.Equal("Auth.AccountExists", result.Error.Code);
        Assert.False(user.HasPassword);
    }

    [Fact]
    public async Task Handle_PasswordLoginDisabled_FailsWithMethodDisabled()
    {
        _ctx.LoginMethods.PasswordEnabled.Returns(false);

        var result = await Register();

        Assert.Equal("Auth.MethodDisabled", result.Error.Code);
        _ctx.Users.DidNotReceive().Add(Arg.Any<User>());
    }
}
