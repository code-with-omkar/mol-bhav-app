using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Features.Identity;
using MolBhav.Application.Features.Identity.GoogleLogin;
using MolBhav.Application.Features.Identity.LinkGoogle;
using MolBhav.Application.Features.Identity.UnlinkGoogle;
using MolBhav.Domain.Common.Exceptions;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Identity;
using static MolBhav.UnitTests.Identity.PasswordLoginTestContext;

namespace MolBhav.UnitTests.Identity;

public sealed class GoogleSignInTests
{
    private const string Token = "google-id-token";
    private static readonly GoogleIdentity Google = new("google-sub-1", "Kisan@Example.com", true, "Ramesh Patil");

    private readonly PasswordLoginTestContext _ctx = new();
    private readonly IGoogleIdTokenVerifier _verifier = Substitute.For<IGoogleIdTokenVerifier>();
    private readonly ICurrentUser _currentUser = Substitute.For<ICurrentUser>();

    public GoogleSignInTests()
    {
        _ctx.LoginMethods.GoogleEnabled.Returns(true);
        _verifier.VerifyAsync(Token, Arg.Any<CancellationToken>()).Returns(Google);
    }

    private Task<Result<LoginSessionResponse>> Login(string? phone = null) =>
        new LoginWithGoogleCommandHandler(_ctx.LoginMethods, _verifier, _ctx.Users, _ctx.RefreshTokens, _ctx.Jwt, _ctx.Clock)
            .Handle(new LoginWithGoogleCommand(Token, phone), CancellationToken.None);

    private User LinkedUser(string? password = Password)
    {
        var user = password is null
            ? User.RegisterWithExternalLogin(PhoneNumber, ExternalLoginProvider.Google, Google.Subject, Google.Email, Google.Name, Now)
            : User.RegisterWithPassword(PhoneNumber, "hash:" + password);
        if (password is not null)
        {
            user.LinkExternalLogin(ExternalLoginProvider.Google, Google.Subject, Google.Email, Now);
        }

        _ctx.Users.GetByExternalLoginAsync(ExternalLoginProvider.Google, Google.Subject, Arg.Any<CancellationToken>()).Returns(user);
        return user;
    }

    [Fact]
    public async Task LinkedGoogleAccount_LogsIn()
    {
        var user = LinkedUser();

        var result = await Login();

        Assert.True(result.IsSuccess);
        Assert.False(result.Value.IsNewUser);
        Assert.Equal(user.Id, result.Value.UserId);
        Assert.Equal(Now, user.LastLoginAtUtc);
    }

    [Fact]
    public async Task NewGoogleAccount_WithoutPhone_AsksForIt()
    {
        var result = await Login();

        Assert.Equal("Auth.PhoneRequired", result.Error.Code);
        _ctx.Users.DidNotReceive().Add(Arg.Any<User>());
    }

    [Fact]
    public async Task NewGoogleAccount_WithPhone_CreatesTheAccountWithGoogleNameAndEmail()
    {
        User? added = null;
        _ctx.Users.When(u => u.Add(Arg.Any<User>())).Do(ci => added = ci.Arg<User>());

        var result = await Login(Phone);

        Assert.True(result.IsSuccess);
        Assert.True(result.Value.IsNewUser);
        Assert.NotNull(added);
        Assert.Equal("Ramesh Patil", added!.DisplayName);
        Assert.False(added.HasPassword);
        var login = Assert.Single(added.ExternalLogins);
        Assert.Equal(("google-sub-1", "kisan@example.com"), (login.Subject, login.Email));
    }

    [Fact]
    public async Task NewGoogleAccount_PhoneAlreadyRegistered_IsRefusedNotLinked()
    {
        var existing = _ctx.ExistingUser();

        var result = await Login(Phone);

        Assert.Equal("Auth.AccountExists", result.Error.Code);
        Assert.Empty(existing.ExternalLogins);
    }

    [Fact]
    public async Task InvalidToken_IsRejected()
    {
        _verifier.VerifyAsync(Token, Arg.Any<CancellationToken>()).Returns((GoogleIdentity?)null);

        var result = await Login(Phone);

        Assert.Equal("Auth.GoogleTokenInvalid", result.Error.Code);
    }

    [Fact]
    public async Task GoogleDisabled_IsRefused()
    {
        _ctx.LoginMethods.GoogleEnabled.Returns(false);

        var result = await Login(Phone);

        Assert.Equal("Auth.MethodDisabled", result.Error.Code);
        await _verifier.DidNotReceive().VerifyAsync(Arg.Any<string>(), Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task Link_GoogleAccountOfAnotherUser_IsRefused()
    {
        LinkedUser();
        var me = User.RegisterWithPassword(PhoneNumber, "hash:x");
        _currentUser.GetRequiredUserId().Returns(me.Id);
        _ctx.Users.GetByIdAsync(me.Id, Arg.Any<CancellationToken>()).Returns(me);

        var result = await new LinkGoogleCommandHandler(_ctx.LoginMethods, _verifier, _ctx.Users, _currentUser, _ctx.Clock)
            .Handle(new LinkGoogleCommand(Token), CancellationToken.None);

        Assert.Equal("Auth.GoogleLinkedElsewhere", result.Error.Code);
        Assert.Empty(me.ExternalLogins);
    }

    [Fact]
    public async Task Link_AddsGoogleToTheSignedInUser()
    {
        var me = User.RegisterWithPassword(PhoneNumber, "hash:x");
        _currentUser.GetRequiredUserId().Returns(me.Id);
        _ctx.Users.GetByIdAsync(me.Id, Arg.Any<CancellationToken>()).Returns(me);

        var result = await new LinkGoogleCommandHandler(_ctx.LoginMethods, _verifier, _ctx.Users, _currentUser, _ctx.Clock)
            .Handle(new LinkGoogleCommand(Token), CancellationToken.None);

        Assert.Equal("kisan@example.com", result.Value.Email);
        Assert.True(me.HasExternalLogin(ExternalLoginProvider.Google));
    }

    [Fact]
    public async Task Unlink_OnlySignInMethod_IsRefused()
    {
        var user = LinkedUser(password: null);
        _currentUser.GetRequiredUserId().Returns(user.Id);
        _ctx.Users.GetByIdAsync(user.Id, Arg.Any<CancellationToken>()).Returns(user);

        var result = await new UnlinkGoogleCommandHandler(_ctx.Users, _currentUser)
            .Handle(new UnlinkGoogleCommand(), CancellationToken.None);

        Assert.Equal("User.LastSignInMethod", result.Error.Code);
        Assert.True(user.HasExternalLogin(ExternalLoginProvider.Google));
    }

    [Fact]
    public void Domain_SecondDifferentGoogleAccount_CannotBeLinked()
    {
        var user = LinkedUser();

        var ex = Assert.Throws<DomainException>(() =>
            user.LinkExternalLogin(ExternalLoginProvider.Google, "another-sub", null, Now));

        Assert.Equal("User.ExternalLoginAlreadyLinked", ex.Code);
    }
}
