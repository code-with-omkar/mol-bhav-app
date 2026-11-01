using MolBhav.Application.Abstractions.AppVersions;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.AppVersions;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;

internal sealed class SetAppVersionPolicyCommandHandler(IAppVersionPolicyRepository policies) : ICommandHandler<SetAppVersionPolicyCommand>
{
    public async Task<Result> Handle(SetAppVersionPolicyCommand request, CancellationToken cancellationToken)
    {
        var existing = await policies.GetCurrentAsync(cancellationToken);
        if (existing is not null)
        {
            return existing.Update(request.MinimumVersion, request.UpdateUrl);
        }

        var created = AppVersionPolicy.Create(request.MinimumVersion, request.UpdateUrl);
        if (created.IsFailure)
        {
            return created.Error;
        }

        policies.Add(created.Value);
        return Result.Success();
    }
}
