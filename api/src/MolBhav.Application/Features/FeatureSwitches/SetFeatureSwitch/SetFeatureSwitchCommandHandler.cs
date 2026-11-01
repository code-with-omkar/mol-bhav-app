using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;

internal sealed class SetFeatureSwitchCommandHandler(IFeatureSwitchRepository switches) : ICommandHandler<SetFeatureSwitchCommand>
{
    public async Task<Result> Handle(SetFeatureSwitchCommand request, CancellationToken cancellationToken)
    {
        var existing = await switches.GetByFeatureAsync(request.Feature, cancellationToken);
        if (existing is not null)
        {
            existing.SetEnabled(request.Enabled);
            return Result.Success();
        }

        var created = FeatureSwitch.Create(request.Feature, request.Enabled);
        if (created.IsFailure)
        {
            return created.Error;
        }

        switches.Add(created.Value);
        return Result.Success();
    }
}
