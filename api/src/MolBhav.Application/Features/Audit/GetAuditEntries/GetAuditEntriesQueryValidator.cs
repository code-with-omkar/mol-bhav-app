using FluentValidation;
using MolBhav.Domain.Audit;

namespace MolBhav.Application.Features.Audit.GetAuditEntries;

internal sealed class GetAuditEntriesQueryValidator : AbstractValidator<GetAuditEntriesQuery>
{
    public GetAuditEntriesQueryValidator()
    {
        RuleFor(x => x.Action).MaximumLength(AuditEntry.ActionMaxLength);
    }
}
