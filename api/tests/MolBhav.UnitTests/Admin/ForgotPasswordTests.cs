using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Notifications;
using MolBhav.Application.Features.Identity.RequestPasswordReset;
using MolBhav.Application.Features.Identity.ResetPassword;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Admin;

public sealed class ForgotPasswordTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 26, 6, 0, 0, TimeSpan.Zero);
    private static readonly PhoneNumber Phone = PhoneNumber.Create("9876543210").Value;

    private readonly ILoginMethods _methods = Substitute.For<ILoginMethods>();
    private readonly IPasswordResetCodeSender _sender = Substitute.For<IPasswordResetCodeSender>();
    private readonly IUserRepository _users = Substitute.For<IUserRepository>();
    private readonly IOtpChallengeRepository _challenges = Substitute.For<IOtpChallengeRepository>();
    private readonly IOtpCodeGenerator _codes = Substitute.For<IOtpCodeGenerator>();
    private readonly IPasswordHasher _hasher = Substitute.For<IPasswordHasher>();
    private readonly IRefreshTokenRepository _tokens = Substitute.For<IRefreshTokenRepository>();
    private OtpChallenge? _stored;

    public ForgotPasswordTests()
    {
        _methods.PasswordEnabled.Returns(true);
        _sender.IsEnabled.Returns(true);
        _codes.GenerateCode().Returns("123456");
        _codes.Hash(Arg.Any<string>(), Arg.Any<string>()).Returns(call => "hash:" + call.ArgAt<string>(1));
        _hasher.Hash(Arg.Any<string>()).Returns(call => "pw:" + call.Arg<string>());
        _tokens.GetActiveForUserAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>()).Returns(new List<RefreshTokenGrant>());
        _challenges.When(c => c.Add(Arg.Any<OtpChallenge>())).Do(call => _stored = call.Arg<OtpChallenge>());
        _challenges.GetLatestForPhoneAsync(Arg.Any<PhoneNumber>(), Arg.Any<CancellationToken>()).Returns(_ => _stored);
    }

    private User AddUser()
    {
        var user = User.Register(Phone);
        user.SetPassword("pw:oldpass12");
        _users.GetByPhoneNumberAsync(Arg.Any<PhoneNumber>(), Arg.Any<CancellationToken>()).Returns(user);
        return user;
    }

    private RequestPasswordResetCommandHandler Request() =>
        new(_methods, _sender, _users, _challenges, _codes, new FixedTimeProvider(Now));

    private ResetPasswordCommandHandler Reset() =>
        new(_methods, _sender, _users, _challenges, _codes, _hasher, _tokens, new FixedTimeProvider(Now));

    [Fact]
    public async Task A_code_is_sent_only_to_a_number_with_an_account_but_both_answers_look_the_same()
    {
        var unknown = await Request().Handle(new RequestPasswordResetCommand("9876543210"), CancellationToken.None);

        Assert.True(unknown.IsSuccess);
        await _sender.DidNotReceiveWithAnyArgs().SendAsync(default!, default!, default);

        _stored = null;
        AddUser();
        var known = await Request().Handle(new RequestPasswordResetCommand("9876543210"), CancellationToken.None);

        Assert.Equal(unknown.Value, known.Value);
        await _sender.Received(1).SendAsync(Arg.Any<PhoneNumber>(), "123456", Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task The_right_code_changes_the_password_and_ends_sessions()
    {
        var user = AddUser();
        var grant = RefreshTokenGrant.IssueInitial(user.Id, "token", Now.AddDays(30));
        _tokens.GetActiveForUserAsync(user.Id, Arg.Any<CancellationToken>()).Returns(new List<RefreshTokenGrant> { grant });
        await Request().Handle(new RequestPasswordResetCommand("9876543210"), CancellationToken.None);

        var result = await Reset().Handle(new ResetPasswordCommand("9876543210", "123456", "newpass12"), CancellationToken.None);

        Assert.Equal(OtpVerificationOutcome.Verified, result.Value.Outcome);
        Assert.Equal("pw:newpass12", user.PasswordHash);
        Assert.NotNull(grant.RevokedAtUtc);
    }

    [Fact]
    public async Task A_wrong_code_changes_nothing_and_counts_the_attempt()
    {
        var user = AddUser();
        await Request().Handle(new RequestPasswordResetCommand("9876543210"), CancellationToken.None);

        var result = await Reset().Handle(new ResetPasswordCommand("9876543210", "000000", "newpass12"), CancellationToken.None);

        Assert.Equal(OtpVerificationOutcome.IncorrectCode, result.Value.Outcome);
        Assert.Equal("pw:oldpass12", user.PasswordHash);
        Assert.Equal(1, _stored!.AttemptCount);
    }

    [Fact]
    public async Task Switched_off_neither_step_works()
    {
        _sender.IsEnabled.Returns(false);

        var request = await Request().Handle(new RequestPasswordResetCommand("9876543210"), CancellationToken.None);
        var reset = await Reset().Handle(new ResetPasswordCommand("9876543210", "123456", "newpass12"), CancellationToken.None);

        Assert.Equal("Auth.MethodDisabled", request.Error.Code);
        Assert.Equal("Auth.MethodDisabled", reset.Error.Code);
    }

    [Fact]
    public void The_new_password_follows_the_policy()
    {
        var validator = new ResetPasswordCommandValidator();

        Assert.False(validator.Validate(new ResetPasswordCommand("9876543210", "123456", "short1")).IsValid);
        Assert.True(validator.Validate(new ResetPasswordCommand("9876543210", "123456", "newpass12")).IsValid);
    }
}
