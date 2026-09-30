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
    long MinAmountPaise) : ICommand<CreatedResponse>;
