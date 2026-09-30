using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Market.Models;

namespace MolBhav.Application.Features.Market.Admin.GetAdminStates;

/// <summary>Full state tree for the admin portal: inactive states/districts included.</summary>
public sealed record GetAdminStatesQuery : IQuery<IReadOnlyList<AdminStateResponse>>;
