using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Admin.Models;

namespace MolBhav.Application.Features.Admin.GetAdminUser;

public sealed record GetAdminUserQuery(Guid UserId) : IQuery<AdminUserDetailResponse>;
