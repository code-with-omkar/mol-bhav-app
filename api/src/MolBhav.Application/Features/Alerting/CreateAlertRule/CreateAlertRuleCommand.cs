using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Alerting;
using MolBhav.Domain.Pricing;

namespace MolBhav.Application.Features.Alerting.CreateAlertRule;

public sealed record CreateAlertRuleCommand(
    Guid ProductId,
    Guid? VariantId,
    LocationKind? LocationKind,
    Guid? MandiId,
    Guid? SupplierId,
    AlertThresholdType? ThresholdType,
    decimal? ThresholdPercent,
    decimal? ThresholdPrice) : ICommand<CreatedResponse>;
