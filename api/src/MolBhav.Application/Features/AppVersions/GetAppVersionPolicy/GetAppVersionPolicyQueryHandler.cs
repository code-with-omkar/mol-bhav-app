using MolBhav.Application.Abstractions.AppVersions;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.AppVersions.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.AppVersions.GetAppVersionPolicy;

internal sealed class GetAppVersionPolicyQueryHandler(IAppVersionPolicyRepository policies)
    : IQueryHandler<GetAppVersionPolicyQuery, AppVersionPolicyResponse>
{
    public async Task<Result<AppVersionPolicyResponse>> Handle(GetAppVersionPolicyQuery request, CancellationToken cancellationToken)
    {
        var policy = await policies.GetCurrentAsync(cancellationToken);
        return new AppVersionPolicyResponse(policy?.MinimumVersion, policy?.UpdateUrl);
    }
}
