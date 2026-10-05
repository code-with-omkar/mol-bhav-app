using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Authentication;

namespace MolBhav.Infrastructure.Authentication;

/// <summary>Bound from <c>Authentication:LoginMethods</c>. Defaults: free password login on, paid SMS OTP off.</summary>
public sealed class LoginMethodsOptions
{
    public const string SectionName = "Authentication:LoginMethods";

    public bool Otp { get; set; }

    public bool Password { get; set; } = true;

    /// <inheritdoc cref="ILoginMethods.AllowClaimingPasswordlessAccounts"/>
    public bool AllowClaimingPasswordlessAccounts { get; set; }
}

internal sealed class ConfiguredLoginMethods(IOptions<LoginMethodsOptions> options, IOptions<GoogleSignInOptions> google)
    : ILoginMethods
{
    public bool OtpEnabled => options.Value.Otp;

    public bool PasswordEnabled => options.Value.Password;

    public bool AllowClaimingPasswordlessAccounts => options.Value.AllowClaimingPasswordlessAccounts;

    public bool GoogleEnabled => google.Value.Enabled && !string.IsNullOrWhiteSpace(google.Value.ServerClientId);

    public string? GoogleServerClientId => GoogleEnabled ? google.Value.ServerClientId : null;
}
