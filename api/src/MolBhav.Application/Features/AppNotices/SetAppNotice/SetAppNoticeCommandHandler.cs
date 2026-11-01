using MolBhav.Application.Abstractions.AppNotices;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.AppNotices;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.AppNotices.SetAppNotice;

internal sealed class SetAppNoticeCommandHandler(IAppNoticeRepository notices) : ICommandHandler<SetAppNoticeCommand>
{
    public async Task<Result> Handle(SetAppNoticeCommand request, CancellationToken cancellationToken)
    {
        var existing = await notices.GetCurrentAsync(cancellationToken);
        if (existing is not null)
        {
            return existing.Update(request.IsActive, request.Severity, request.Message);
        }

        var created = AppNotice.Create(request.IsActive, request.Severity, request.Message);
        if (created.IsFailure)
        {
            return created.Error;
        }

        notices.Add(created.Value);
        return Result.Success();
    }
}
