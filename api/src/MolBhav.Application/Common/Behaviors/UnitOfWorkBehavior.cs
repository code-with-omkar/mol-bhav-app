using MediatR;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Common.Behaviors;

/// <summary>
/// Innermost behaviour, commands only: the handler plus SaveChanges run in one ACID transaction.
/// A failed <see cref="Result"/> rolls back, so handlers never need to call SaveChanges themselves.
/// Queries are excluded by the <see cref="IBaseCommand"/> constraint (the DI container skips this behaviour for them).
/// </summary>
internal sealed class UnitOfWorkBehavior<TRequest, TResponse>(IUnitOfWork unitOfWork)
    : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IBaseCommand
    where TResponse : Result
{
    public Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken) =>
        unitOfWork.ExecuteInTransactionAsync(
            async token =>
            {
                var response = await next();

                if (response.IsSuccess)
                {
                    await unitOfWork.SaveChangesAsync(token);
                }

                return response;
            },
            response => response.IsSuccess,
            cancellationToken);
}
