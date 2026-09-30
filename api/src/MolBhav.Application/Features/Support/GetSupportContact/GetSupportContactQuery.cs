using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Support.Models;

namespace MolBhav.Application.Features.Support.GetSupportContact;

public sealed record GetSupportContactQuery : IQuery<SupportContactResponse>;
