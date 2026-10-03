using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Identity.GetLoginMethods;

internal sealed class GetLoginMethodsQueryHandler(ILoginMethods loginMethods)
    : IQueryHandler<GetLoginMethodsQuery, LoginMethodsResponse>
{
    public Task<Result<LoginMethodsResponse>> Handle(GetLoginMethodsQuery request, CancellationToken cancellationToken) =>
        Task.FromResult(Result.Success(new LoginMethodsResponse(loginMethods.OtpEnabled, loginMethods.PasswordEnabled)));
}
