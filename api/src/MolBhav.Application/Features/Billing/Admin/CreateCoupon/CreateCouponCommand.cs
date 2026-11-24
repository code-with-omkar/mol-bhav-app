using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Billing;

namespace MolBhav.Application.Features.Billing.Admin.CreateCoupon;

public sealed record CreateCouponCommand(
    string Code,
    DiscountType DiscountType,
    long DiscountValue,
    int? MaxUses,
    DateTimeOffset ValidFrom,
    DateTimeOffset? ValidTo,
    string? ApplicablePlanCode,
    long MinAmountPaise) : ICommand<CreatedResponse>, IAuditedCommand
{
    string IAuditedCommand.AuditAction => "Coupon.Create";

    string? IAuditedCommand.AuditTarget => Coupon.NormaliseCode(Code ?? string.Empty);

    string IAuditedCommand.AuditSummary => DiscountType == DiscountType.Percent
        ? $"Created a {DiscountValue}% coupon"
        : $"Created a coupon worth {DiscountValue / 100m:0.##} rupees off";
}
