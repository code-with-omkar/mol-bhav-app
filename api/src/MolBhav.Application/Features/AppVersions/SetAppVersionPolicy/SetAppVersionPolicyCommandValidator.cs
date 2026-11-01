using FluentValidation;
using MolBhav.Domain.AppVersions;

namespace MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;

internal sealed class SetAppVersionPolicyCommandValidator : AbstractValidator<SetAppVersionPolicyCommand>
{
    public SetAppVersionPolicyCommandValidator()
    {
        RuleFor(x => x.MinimumVersion).MaximumLength(AppVersionPolicy.VersionMaxLength);
        RuleFor(x => x.UpdateUrl).MaximumLength(AppVersionPolicy.UrlMaxLength);
    }
}
