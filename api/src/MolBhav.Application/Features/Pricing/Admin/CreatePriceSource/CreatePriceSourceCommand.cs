using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;

namespace MolBhav.Application.Features.Pricing.Admin.CreatePriceSource;

/// <param name="Code">Immutable source code (adapters and parsers are keyed by it), e.g. <c>agmarknet</c>.</param>
/// <param name="Name">Display name.</param>
/// <param name="CategoryCode">Procurement category the source prices (e.g. <c>agriculture</c>, <c>construction</c>).</param>
public sealed record CreatePriceSourceCommand(string Code, string Name, string CategoryCode) : ICommand<CreatedResponse>;
