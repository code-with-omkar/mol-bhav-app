using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Pricing;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Pricing.Admin.VoidPriceRecord;

internal sealed class VoidPriceRecordCommandHandler(IPriceRecordRepository records) : ICommandHandler<VoidPriceRecordCommand>
{
    public async Task<Result> Handle(VoidPriceRecordCommand request, CancellationToken cancellationToken)
    {
        var record = await records.GetByIdAsync(request.PriceRecordId, cancellationToken);
        if (record is null)
        {
            return Error.NotFound("PriceRecord.NotFound", "Price record not found.");
        }

        record.Void();
        return Result.Success();
    }
}
