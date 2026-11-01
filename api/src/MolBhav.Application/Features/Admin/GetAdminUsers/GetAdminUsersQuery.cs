using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Identity;

namespace MolBhav.Application.Features.Admin.GetAdminUsers;

/// <summary>The admin's user list, newest first, filtered by search text, status and plan.</summary>
public sealed record GetAdminUsersQuery(string? Search, UserStatus? Status, SubscriptionTier? Tier, int Page, int PageSize)
    : IQuery<PagedResult<AdminUserResponse>>;
