using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Features.Admin.ResetUserPassword;
using MolBhav.Application.Features.Identity.ChangePassword;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.UnitTests.Admin;

public sealed class PasswordManagementTests
{
    private readonly IUserRepository _users = Substitute.For<IUserRepository>();
    private readonly ICurrentUser _currentUser = Substitute.For<ICurrentUser>();
    private readonly IPasswordHasher _hasher = Substitute.For<IPasswordHasher>();
    private readonly IRefreshTokenRepository _tokens = Substitute.For<IRefreshTokenRepository>();
    private readonly Guid _admin = Guid.CreateVersion7();

    private RefreshTokenGrant GrantFor(User user)
    {
        var grant = RefreshTokenGrant.IssueInitial(user.Id, "token-hash", DateTimeOffset.UtcNow.AddDays(30));
        _tokens.GetActiveForUserAsync(user.Id, Arg.Any<CancellationToken>())
            .Returns(new List<RefreshTokenGrant> { grant });
        return grant;
    }

    public PasswordManagementTests()
    {
        _hasher.Hash(Arg.Any<string>()).Returns(call => "hash:" + call.Arg<string>());
        _hasher.Verify(Arg.Any<string?>(), Arg.Any<string>())
            .Returns(call => call.ArgAt<string?>(0) == "hash:" + call.ArgAt<string>(1)
                ? PasswordVerificationResult.Success
                : PasswordVerificationResult.Failed);
    }

    private static User NewUser(UserRole role = UserRole.User, string? passwordHash = null)
    {
        var user = User.Register(PhoneNumber.Create("9876543210").Value);
        typeof(User).GetProperty(nameof(User.Role))!.SetValue(user, role);
        if (passwordHash is not null)
        {
            user.SetPassword(passwordHash);
        }

        return user;
    }

    private ChangePasswordCommandHandler ChangeHandler(User user)
    {
        _currentUser.GetRequiredUserId().Returns(user.Id);
        _users.GetByIdAsync(user.Id, Arg.Any<CancellationToken>()).Returns(user);
        return new ChangePasswordCommandHandler(_users, _currentUser, _hasher, _tokens, TimeProvider.System);
    }

    private ResetUserPasswordCommandHandler ResetHandler(User? user)
    {
        _users.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>()).Returns(user);
        return new ResetUserPasswordCommandHandler(_users, _hasher, _tokens, TimeProvider.System);
    }

    [Fact]
    public async Task Changing_the_password_needs_the_current_one()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");

        var wrong = await ChangeHandler(user).Handle(new("nope1234", "newpass12"), CancellationToken.None);
        Assert.Equal("Password.CurrentIncorrect", wrong.Error.Code);
        Assert.Equal("hash:oldpass1", user.PasswordHash);

        var right = await ChangeHandler(user).Handle(new("oldpass1", "newpass12"), CancellationToken.None);
        Assert.True(right.IsSuccess);
        Assert.Equal("hash:newpass12", user.PasswordHash);
    }

    [Fact]
    public async Task An_account_without_a_password_can_set_its_first_one()
    {
        var user = NewUser();

        var result = await ChangeHandler(user).Handle(new(null, "newpass12"), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal("hash:newpass12", user.PasswordHash);
    }

    [Fact]
    public void The_new_password_follows_the_policy_and_must_differ()
    {
        var validator = new ChangePasswordCommandValidator();

        Assert.False(validator.Validate(new ChangePasswordCommand("oldpass1", "short1")).IsValid);
        Assert.False(validator.Validate(new ChangePasswordCommand("oldpass1", "onlyletters")).IsValid);
        Assert.False(validator.Validate(new ChangePasswordCommand("oldpass1", "oldpass1")).IsValid);
        Assert.True(validator.Validate(new ChangePasswordCommand("oldpass1", "newpass12")).IsValid);
    }

    [Fact]
    public async Task An_admin_resets_a_users_password_and_gets_a_usable_one()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");

        var result = await ResetHandler(user).Handle(new(user.Id, _admin), CancellationToken.None);

        Assert.True(result.IsSuccess);
        var password = result.Value.TemporaryPassword;
        Assert.Equal(12, password.Length);
        Assert.Contains(password, char.IsLetter);
        Assert.Contains(password, char.IsDigit);
        Assert.Equal("hash:" + password, user.PasswordHash);
    }

    [Fact]
    public async Task A_reset_clears_a_lockout()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");
        for (var i = 0; i < User.MaxFailedPasswordAttempts; i++)
        {
            user.RecordFailedPasswordAttempt(DateTimeOffset.UtcNow);
        }

        Assert.True(user.IsPasswordLockedOut(DateTimeOffset.UtcNow));

        await ResetHandler(user).Handle(new(user.Id, _admin), CancellationToken.None);

        Assert.False(user.IsPasswordLockedOut(DateTimeOffset.UtcNow));
    }

    [Fact]
    public async Task Nobody_resets_their_own_or_an_admins_password()
    {
        var admin = NewUser(UserRole.Admin, "hash:adminpass1");

        var own = await ResetHandler(admin).Handle(new(admin.Id, admin.Id), CancellationToken.None);
        Assert.Equal("User.CannotResetOwnPassword", own.Error.Code);

        var other = await ResetHandler(admin).Handle(new(admin.Id, _admin), CancellationToken.None);
        Assert.Equal("User.AdminPasswordNotResettable", other.Error.Code);
        Assert.Equal("hash:adminpass1", admin.PasswordHash);
    }

    [Fact]
    public async Task Changing_the_password_ends_every_session()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");
        var grant = GrantFor(user);

        await ChangeHandler(user).Handle(new("oldpass1", "newpass12"), CancellationToken.None);

        Assert.NotNull(grant.RevokedAtUtc);
    }

    [Fact]
    public async Task A_wrong_current_password_keeps_the_sessions()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");
        var grant = GrantFor(user);

        await ChangeHandler(user).Handle(new("nope1234", "newpass12"), CancellationToken.None);

        Assert.Null(grant.RevokedAtUtc);
    }

    [Fact]
    public async Task An_admin_reset_ends_the_users_sessions()
    {
        var user = NewUser(passwordHash: "hash:oldpass1");
        var grant = GrantFor(user);

        await ResetHandler(user).Handle(new(user.Id, _admin), CancellationToken.None);

        Assert.NotNull(grant.RevokedAtUtc);
    }

    [Fact]
    public async Task An_unknown_user_is_not_found()
    {
        var result = await ResetHandler(null).Handle(new(Guid.CreateVersion7(), _admin), CancellationToken.None);

        Assert.Equal("User.NotFound", result.Error.Code);
    }
}
