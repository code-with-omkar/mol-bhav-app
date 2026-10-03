using FluentValidation;

namespace MolBhav.Application.Features.Identity;

/// <summary>
/// Password rules for new passwords (OWASP ASVS 2.1: length over composition; one letter + one digit as a light floor).
/// The upper bound keeps the hash cost bounded per request.
/// </summary>
internal static class PasswordPolicy
{
    public const int MinLength = 8;
    public const int MaxLength = 128;

    public static IRuleBuilderOptions<T, string> NewPassword<T>(this IRuleBuilder<T, string> rule) =>
        rule.NotEmpty()
            .MinimumLength(MinLength)
            .MaximumLength(MaxLength)
            .Must(p => p.Any(char.IsLetter) && p.Any(char.IsDigit))
            .WithErrorCode("Password.TooWeak")
            .WithMessage($"Use at least {MinLength} characters with at least one letter and one number.");
}
