using MolBhav.Application.Abstractions.AppNotices;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.AppNotices.Models;
using MolBhav.Domain.AppNotices;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.AppNotices.GetAppNotice;

internal sealed class GetAppNoticeQueryHandler(IAppNoticeRepository notices) : IQueryHandler<GetAppNoticeQuery, AppNoticeResponse>
{
    public async Task<Result<AppNoticeResponse>> Handle(GetAppNoticeQuery request, CancellationToken cancellationToken)
    {
        var notice = await notices.GetCurrentAsync(cancellationToken);
        if (notice is null)
        {
            return new AppNoticeResponse(false, NoticeSeverity.Info, string.Empty, null);
        }

        // Users never receive the text of a notice that is off.
        return notice.IsActive || request.ForEditing
            ? new AppNoticeResponse(notice.IsActive, notice.Severity, notice.Message, notice.UpdatedAtUtc ?? notice.CreatedAtUtc)
            : new AppNoticeResponse(false, NoticeSeverity.Info, string.Empty, notice.UpdatedAtUtc ?? notice.CreatedAtUtc);
    }
}
