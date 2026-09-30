using MolBhav.Application.Abstractions.Market;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Market.Admin.UpdateSupplier;

internal sealed class UpdateSupplierCommandHandler(ISupplierRepository suppliers, IStateRepository states) : ICommandHandler<UpdateSupplierCommand>
{
    public async Task<Result> Handle(UpdateSupplierCommand request, CancellationToken cancellationToken)
    {
        var supplier = await suppliers.GetByIdAsync(request.SupplierId, cancellationToken);
        if (supplier is null)
        {
            return Error.NotFound("Supplier.NotFound", "Supplier not found.");
        }

        if (!await states.DistrictExistsAsync(request.DistrictId, cancellationToken))
        {
            return Error.Validation("District.NotFound", "District does not exist.");
        }

        return supplier.Update(request.DistrictId, request.Name, request.ContactPhone, request.IsActive!.Value);
    }
}
