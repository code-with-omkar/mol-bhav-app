using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.FeatureSwitches.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.FeatureSwitches;

namespace MolBhav.Application.Features.FeatureSwitches.GetFeatureSwitches;

internal sealed class GetFeatureSwitchesQueryHandler(IFeatureSwitchRepository switches)
    : IQueryHandler<GetFeatureSwitchesQuery, IReadOnlyList<FeatureSwitchResponse>>
{
    public async Task<Result<IReadOnlyList<FeatureSwitchResponse>>> Handle(GetFeatureSwitchesQuery request, CancellationToken cancellationToken)
    {
        var saved = (await switches.ListAsync(cancellationToken)).ToDictionary(s => s.Feature, s => s.IsEnabled);

        // Always the full list, in a fixed order, so the app and admin never have to guess what is missing.
        IReadOnlyList<FeatureSwitchResponse> all =
        [
            .. Enum.GetValues<AppFeature>().Select(f => new FeatureSwitchResponse(f, saved.GetValueOrDefault(f, true))),
        ];
        return Result.Success(all);
    }
}
