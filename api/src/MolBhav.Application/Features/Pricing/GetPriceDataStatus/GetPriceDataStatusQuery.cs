using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Pricing.Models;

namespace MolBhav.Application.Features.Pricing.GetPriceDataStatus;

/// <summary>Are the automatically refreshed price feeds (e.g. Agmarknet via data.gov.in) keeping up? Drives the app's "prices may be delayed" banner.</summary>
public sealed record GetPriceDataStatusQuery : IQuery<PriceDataStatusResponse>;
