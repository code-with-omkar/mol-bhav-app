using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Identity;

/// <summary>Shared substitutes for the password login/registration handlers. The hasher is faked: "hash:{password}".</summary>
internal sealed class PasswordLoginTestContext
{
    public const string Phone = "9876543210";
    public const string Password = "kanda2026";

    public static readonly DateTimeOffset Now = new(2026, 10, 3, 6, 0, 0, TimeSpan.Zero);

    public PasswordLoginTestContext()
    {
        LoginMethods.PasswordEnabled.Returns(true);
        LoginMethods.OtpEnabled.Returns(false);

        Hasher.Hash(Arg.Any<string>()).Returns(ci => "hash:" + ci.Arg<string>());
        Hasher.Verify(Arg.Any<string?>(), Arg.Any<string>()).Returns(ci =>
            ci.ArgAt<string?>(0) == "hash:" + ci.ArgAt<string>(1)
                ? PasswordVerificationResult.Success
                : PasswordVerificationResult.Failed);

        Jwt.CreateAccessToken(Arg.Any<TokenSubject>()).Returns(new AccessToken("access", Now.AddMinutes(15)));
        Jwt.CreateRefreshToken().Returns(new RefreshToken("refresh", "refresh-hash", Now.AddDays(30)));
    }

    public ILoginMethods LoginMethods { get; } = Substitute.For<ILoginMethods>();

    public IUserRepository Users { get; } = Substitute.For<IUserRepository>();

    public IRefreshTokenRepository RefreshTokens { get; } = Substitute.For<IRefreshTokenRepository>();

    public IPasswordHasher Hasher { get; } = Substitute.For<IPasswordHasher>();

    public IJwtTokenService Jwt { get; } = Substitute.For<IJwtTokenService>();

    public TimeProvider Clock { get; } = new FixedTimeProvider(Now);

    public static PhoneNumber PhoneNumber => Domain.SharedKernel.PhoneNumber.Create(Phone).Value;

    public User ExistingUser(string? password = Password)
    {
        var user = password is null ? User.Register(PhoneNumber) : User.RegisterWithPassword(PhoneNumber, "hash:" + password);
        Users.GetByPhoneNumberAsync(PhoneNumber, Arg.Any<CancellationToken>()).Returns(user);
        return user;
    }
}
