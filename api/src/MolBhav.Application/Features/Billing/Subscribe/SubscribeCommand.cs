using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Billing.Models;

namespace MolBhav.Application.Features.Billing.Subscribe;

public sealed record SubscribeCommand(string PlanCode, string? CouponCode) : ICommand<SubscribeResponseDto>;
