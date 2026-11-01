using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Admin.GetAdminUser;

internal sealed class GetAdminUserQueryHandler(IAdminUserReadService readService)
    : IQueryHandler<GetAdminUserQuery, AdminUserDetailResponse>
{
    public async Task<Result<AdminUserDetailResponse>> Handle(GetAdminUserQuery request, CancellationToken cancellationToken) =>
        await readService.GetUserAsync(request.UserId, cancellationToken) is { } user
            ? user
            : Error.NotFound("User.NotFound", "User not found.");
}
