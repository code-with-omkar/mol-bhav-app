using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Promotions;

namespace MolBhav.Application.Features.Promotions.Admin.CreateAdvertiser;

internal sealed class CreateAdvertiserCommandHandler(IAdvertiserRepository advertisers)
    : ICommandHandler<CreateAdvertiserCommand, CreatedResponse>
{
    public Task<Result<CreatedResponse>> Handle(CreateAdvertiserCommand request, CancellationToken cancellationToken)
    {
        var advertiser = Advertiser.Create(request.Name, request.ContactName, request.ContactPhone, request.Gstin);
        if (advertiser.IsFailure)
        {
            return Task.FromResult(Result.Failure<CreatedResponse>(advertiser.Error));
        }

        advertisers.Add(advertiser.Value);
        return Task.FromResult(Result.Success(new CreatedResponse(advertiser.Value.Id)));
    }
}
