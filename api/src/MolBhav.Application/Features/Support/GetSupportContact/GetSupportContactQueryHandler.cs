using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Support;
using MolBhav.Application.Features.Support.Models;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Support.GetSupportContact;

internal sealed class GetSupportContactQueryHandler(ISupportContactProvider contacts)
    : IQueryHandler<GetSupportContactQuery, SupportContactResponse>
{
    public Task<Result<SupportContactResponse>> Handle(GetSupportContactQuery request, CancellationToken cancellationToken)
    {
        var contact = contacts.GetContact();
        return Task.FromResult(Result.Success(new SupportContactResponse(contact.WhatsAppNumber, contact.Phone, contact.Email)));
    }
}
