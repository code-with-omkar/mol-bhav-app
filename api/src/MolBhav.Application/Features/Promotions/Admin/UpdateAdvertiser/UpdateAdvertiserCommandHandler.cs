using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.UpdateAdvertiser;

internal sealed class UpdateAdvertiserCommandHandler(IAdvertiserRepository advertisers) : ICommandHandler<UpdateAdvertiserCommand>
{
    public async Task<Result> Handle(UpdateAdvertiserCommand request, CancellationToken cancellationToken)
    {
        var advertiser = await advertisers.GetByIdAsync(request.AdvertiserId, cancellationToken);
        return advertiser is null
            ? PromotionErrors.AdvertiserNotFound
            : advertiser.Update(request.Name, request.ContactName, request.ContactPhone, request.Gstin);
    }
}
