using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Promotions.Models;

namespace MolBhav.Application.Features.Promotions.RecordPromotionEvents;

/// <summary>Impressions and clicks the app batched up since its last report.</summary>
public sealed record RecordPromotionEventsCommand(IReadOnlyList<PromotionEventInput>? Events) : ICommand;
