using FluentValidation;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.UpdateProfile;

/// <summary>Structural checks only — <c>LanguageCode.Create</c>/<c>ProcurementCategoryCode.Create</c> in the handler give the stable, localizable errorCodes.</summary>
internal sealed class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    public UpdateProfileCommandValidator()
    {
        RuleFor(x => x.BusinessType).MaximumLength(UserProfile.FieldMaxLength);
        RuleFor(x => x.State).MaximumLength(UserProfile.FieldMaxLength);
        RuleFor(x => x.District).MaximumLength(UserProfile.FieldMaxLength);

        RuleFor(x => x.PreferredLanguage)
            .NotEmpty()
            .MaximumLength(LanguageCode.MaxLength);

        RuleFor(x => x.Categories)
            .NotNull()
            .Must(c => c.Count <= User.MaxCategories)
            .WithMessage($"A user can watch at most {User.MaxCategories} procurement categories.");

        RuleForEach(x => x.Categories).MaximumLength(ProcurementCategoryCode.MaxLength);
    }
}
