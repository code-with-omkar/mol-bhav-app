using FluentValidation;

namespace MolBhav.Application.Features.Identity.GoogleLogin;

internal sealed class LoginWithGoogleCommandValidator : AbstractValidator<LoginWithGoogleCommand>
{
    /// <summary>Google ID tokens are ~1–2 KB; anything far larger is not one.</summary>
    public const int MaxIdTokenLength = 8192;

    public LoginWithGoogleCommandValidator()
    {
        RuleFor(x => x.IdToken).NotEmpty().MaximumLength(MaxIdTokenLength);
        RuleFor(x => x.PhoneNumber).MaximumLength(20);
    }
}
