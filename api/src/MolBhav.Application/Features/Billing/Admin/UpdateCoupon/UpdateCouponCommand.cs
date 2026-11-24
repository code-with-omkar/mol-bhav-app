using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Billing.Admin.UpdateCoupon;

/// <summary>Full replacement of the editable fields: null <see cref="ValidTo"/> / <see cref="MaxUses"/> means open-ended / unlimited.</summary>
public sealed record UpdateCouponCommand(Guid Id, bool IsActive, DateTimeOffset? ValidTo, int? MaxUses) : ICommand, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Coupon.Update";

    string? IAuditedCommand.AuditTarget => Id.ToString();

    string IAuditedCommand.AuditSummary => IsActive ? "Edited a coupon (on)" : "Edited a coupon (switched off)";
}
