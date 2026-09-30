using MolBhav.Application.Abstractions.Messaging;

namespace MolBhav.Application.Features.Market.Admin.UpdateState;

/// <summary>Full replacement of editable fields. The code is immutable (ingestion/admin filters reference it).</summary>
public sealed record UpdateStateCommand(Guid StateId, string Name, bool? IsActive) : ICommand;
