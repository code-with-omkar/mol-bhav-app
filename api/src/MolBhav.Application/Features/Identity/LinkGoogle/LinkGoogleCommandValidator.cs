using FluentValidation;
using MolBhav.Application.Features.Identity.GoogleLogin;

namespace MolBhav.Application.Features.Identity.LinkGoogle;

internal sealed class LinkGoogleCommandValidator : AbstractValidator<LinkGoogleCommand>
{
    public LinkGoogleCommandValidator() =>
        RuleFor(x => x.IdToken).NotEmpty().MaximumLength(LoginWithGoogleCommandValidator.MaxIdTokenLength);
}
