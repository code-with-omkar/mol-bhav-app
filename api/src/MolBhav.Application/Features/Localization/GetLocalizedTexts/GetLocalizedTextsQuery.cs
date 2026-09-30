using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Localization.GetLocalizedTexts;

/// <summary>Mobile app fetch of data-driven strings (BRD §18: "database/config-driven localized metadata") for the request's negotiated language.</summary>
public sealed record GetLocalizedTextsQuery(string? KeyPrefix) : IQuery<IReadOnlyDictionary<string, string>>;
