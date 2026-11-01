using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Application.Features.Admin.GetAdminDashboard;

/// <summary>Headline numbers for the admin app's landing screen.</summary>
public sealed record GetAdminDashboardQuery : IQuery<AdminDashboardResponse>;
