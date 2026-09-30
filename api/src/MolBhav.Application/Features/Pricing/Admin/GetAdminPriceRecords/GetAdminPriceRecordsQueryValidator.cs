using FluentValidation;

namespace MolBhav.Application.Features.Pricing.Admin.GetAdminPriceRecords;

internal sealed class GetAdminPriceRecordsQueryValidator : AbstractValidator<GetAdminPriceRecordsQuery>
{
    public GetAdminPriceRecordsQueryValidator() =>
        RuleFor(x => x.ToDate).GreaterThanOrEqualTo(x => x.FromDate!.Value)
            .When(x => x.FromDate is not null && x.ToDate is not null)
            .WithMessage("toDate must not be before fromDate.");
}
