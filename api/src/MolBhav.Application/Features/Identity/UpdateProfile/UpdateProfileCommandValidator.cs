using System.Text.RegularExpressions;
using FluentValidation;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.UpdateProfile;

/// <summary>Structural checks only — <c>LanguageCode.Create</c>/<c>ProcurementCategoryCode.Create</c> in the handler give the stable, localizable errorCodes.</summary>
internal sealed class UpdateProfileCommandValidator : AbstractValidator<UpdateProfileCommand>
{
    // Letters and combining marks (Indic vowel signs, viramas) in any script, plus space . ' -; must start with a letter.
    private static readonly Regex DisplayNamePattern = new(@"^\p{L}[\p{L}\p{M} .'\-]*$", RegexOptions.Compiled);

    public UpdateProfileCommandValidator()
    {
        RuleFor(x => User.NormaliseDisplayName(x.DisplayName))
            .Length(User.DisplayNameMinLength, User.DisplayNameMaxLength)
            .Matches(DisplayNamePattern)
            .WithMessage("Name may contain only letters, spaces, and . ' -")
            .OverridePropertyName(nameof(UpdateProfileCommand.DisplayName))
            .When(x => User.NormaliseDisplayName(x.DisplayName) is not null);

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
