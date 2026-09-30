using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.ValidateCoupon;

/// <summary>Prices a coupon against a plan without consuming a use. The plan code identifies the billing cycle.</summary>
public sealed record ValidateCouponQuery(string Code, string PlanCode) : IQuery<CouponValidationDto>;
