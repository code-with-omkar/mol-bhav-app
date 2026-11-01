using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Admin.GetAdminUsers;

internal sealed class GetAdminUsersQueryHandler(IAdminUserReadService readService)
    : IQueryHandler<GetAdminUsersQuery, PagedResult<AdminUserResponse>>
{
    public async Task<Result<PagedResult<AdminUserResponse>>> Handle(GetAdminUsersQuery request, CancellationToken cancellationToken) =>
        Result.Success(await readService.GetUsersAsync(
            new AdminUserFilter(request.Search?.Trim(), request.Status, request.Tier, new PageRequest(request.Page, request.PageSize)),
            cancellationToken));
}
