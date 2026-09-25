using MediatR;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Abstractions.Messaging;

/// <summary>Side-effect-free read request. Never wrapped in a unit-of-work transaction.</summary>
public interface IQuery<TResponse> : IRequest<Result<TResponse>>
{
}
