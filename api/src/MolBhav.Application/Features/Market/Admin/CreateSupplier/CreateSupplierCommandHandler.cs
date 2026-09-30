using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Market;

namespace MolBhav.Application.Features.Market.Admin.CreateSupplier;

internal sealed class CreateSupplierCommandHandler(ISupplierRepository suppliers, IStateRepository states)
    : ICommandHandler<CreateSupplierCommand, CreatedResponse>
{
    public async Task<Result<CreatedResponse>> Handle(CreateSupplierCommand request, CancellationToken cancellationToken)
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
        if (await suppliers.CodeExistsAsync(code.Value, cancellationToken))
        {
            return Error.Conflict("Supplier.CodeTaken", $"Supplier '{code.Value.Value}' already exists.");
        }

        var supplier = Supplier.Create(code.Value, request.DistrictId, request.Name, request.ContactPhone);
        if (supplier.IsFailure)
        {
            return Result.Failure<CreatedResponse>(supplier.Error);
        }

        suppliers.Add(supplier.Value);
        return new CreatedResponse(supplier.Value.Id);
    }
}
