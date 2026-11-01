using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Application.Abstractions.Admin;

/// <summary>Dapper-backed counts for the admin dashboard (users, ads, support). Feed health comes from <c>IIngestionReadService</c>.</summary>
public interface IAdminDashboardReadService
{
    /// <summary>
    /// <paramref name="today"/> is the IST day for "today" figures; the 7-day windows end with it (ads) or at
    /// <paramref name="nowUtc"/> (users, rewarded views).
    /// </summary>
    Task<DashboardCounts> GetCountsAsync(DateOnly today, DateTimeOffset nowUtc, CancellationToken cancellationToken = default);
}

/// <summary>Everything the dashboard needs from the database, before it is shaped for the response.</summary>
public sealed record DashboardCounts(AdminUsersSummary Users, AdminAdsSummary Ads, AdminSupportSummary Support);
