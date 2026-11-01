using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.AppNotices;

namespace MolBhav.Application.Features.AppNotices.SetAppNotice;

/// <summary>Creates the app's notice the first time, then edits it: turn it on or off, change its type or text.</summary>
public sealed record SetAppNoticeCommand(bool IsActive, NoticeSeverity Severity, string? Message) : ICommand;
