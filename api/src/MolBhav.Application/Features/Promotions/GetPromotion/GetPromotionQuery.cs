using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.GetPromotion;

public sealed record GetPromotionQuery(PromotionPlacement? Placement) : IQuery<PromotionSlotResponse>;
