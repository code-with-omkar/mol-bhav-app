using MediatR;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Abstractions.Messaging;

/// <summary>Marker used by pipeline behaviours to recognise state-changing requests (wrapped in a transaction).</summary>
public interface IBaseCommand
{
}

/// <summary>State-changing request with no return value.</summary>
public interface ICommand : IRequest<Result>, IBaseCommand
{
}

/// <summary>State-changing request that returns a value (e.g. the created identifier).</summary>
public interface ICommand<TResponse> : IRequest<Result<TResponse>>, IBaseCommand
{
}
