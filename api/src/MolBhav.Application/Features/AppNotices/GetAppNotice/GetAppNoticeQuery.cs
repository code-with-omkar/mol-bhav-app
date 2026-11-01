using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.AppNotices.Models;

namespace MolBhav.Application.Features.AppNotices.GetAppNotice;

/// <summary>The notice the app should show. With <paramref name="ForEditing"/> (admin) an off notice still returns its saved text.</summary>
public sealed record GetAppNoticeQuery(bool ForEditing = false) : IQuery<AppNoticeResponse>;
