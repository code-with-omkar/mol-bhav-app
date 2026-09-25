using FluentValidation;

namespace MolBhav.Application.Features.Identity.RequestOtp;

/// <summary>Structural check only — the semantic Indian-mobile-number rule lives in <c>PhoneNumber.Create</c> (errorCode <c>PhoneNumber.Invalid</c>).</summary>
internal sealed class RequestOtpCommandValidator : AbstractValidator<RequestOtpCommand>
{
    public RequestOtpCommandValidator()
    {
        RuleFor(x => x.PhoneNumber)
            .NotEmpty()
            .MaximumLength(20);
    }
}
