using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateMandi;

internal sealed class CreateMandiCommandHandler(IMandiRepository mandis, IStateRepository states) : ICommandHandler<CreateMandiCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateMandiCommand request, CancellationToken cancellationToken)
    {
        var code = MarketCode.Create(request.Code);
        if (code.IsFailure)
        {
            return Result.Failure<CreatedResponse>(code.Error);
        }

        if (!await states.DistrictExistsAsync(request.DistrictId, cancellationToken))
        {
            return Error.Validation("District.NotFound", "District does not exist.");
        }

        // Friendly pre-check; the unique index is the race-proof backstop (→ 409).
        if (await mandis.CodeExistsAsync(code.Value, cancellationToken))
        {
            return Error.Conflict("Mandi.CodeTaken", $"Mandi '{code.Value.Value}' already exists.");
        }

        var mandi = Mandi.Create(code.Value, request.DistrictId, request.Name);
        if (mandi.IsFailure)
        {
            return Result.Failure<CreatedResponse>(mandi.Error);
        }

        mandis.Add(mandi.Value);
        return new CreatedResponse(mandi.Value.Id);
    }
}
