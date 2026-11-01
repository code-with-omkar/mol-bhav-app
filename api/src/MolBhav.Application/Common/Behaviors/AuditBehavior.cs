using MediatR;
using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Domain.Audit;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Common.Behaviors;

/// <summary>
/// Records a successful <see cref="IAuditedCommand"/> in the audit log. Registered inside <see cref="UnitOfWorkBehavior{TRequest, TResponse}"/>,
/// so the entry is saved in the same transaction as the change: both happen or neither does. A command with no signed-in
/// user (a background job) is not an admin action and is skipped.
/// </summary>
internal sealed class AuditBehavior<TRequest, TResponse>(
    IAuditEntryRepository entries,
    ICurrentUser currentUser,
    TimeProvider timeProvider) : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IAuditedCommand
    where TResponse : Result
{
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var response = await next(cancellationToken);

        if (response.IsSuccess && currentUser.UserId is { } actor)
        {
            entries.Add(AuditEntry.Create(actor, request.AuditAction, request.AuditTarget, request.AuditSummary, timeProvider.GetUtcNow()));
        }

        return response;
    }
}
