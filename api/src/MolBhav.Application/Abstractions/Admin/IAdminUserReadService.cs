using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Abstractions.Admin;

/// <summary>Dapper-backed reads for the admin's user management (soft-deleted accounts are never listed).</summary>
public interface IAdminUserReadService
{
    Task<PagedResult<AdminUserResponse>> GetUsersAsync(AdminUserFilter filter, CancellationToken cancellationToken = default);

    /// <summary>Null when the user does not exist (or was deleted).</summary>
    Task<AdminUserDetailResponse?> GetUserAsync(Guid userId, CancellationToken cancellationToken = default);
}

/// <param name="Search">Matches part of the phone number or display name (case-insensitive); null/blank = everyone.</param>
public sealed record AdminUserFilter(string? Search, UserStatus? Status, SubscriptionTier? Tier, PageRequest Page);
