using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Application.Features.Monetization.Models;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Features.Monetization.GetAdUnlockSession;

/// <summary>Polled by the app after each ad until the signed callback has granted the unlock.</summary>
internal sealed class GetAdUnlockSessionQueryHandler(IAdUnlockSessionRepository sessions, ICurrentUser currentUser)
    : IQueryHandler<GetAdUnlockSessionQuery, AdUnlockSessionResponse>
{
    public async Task<Result<AdUnlockSessionResponse>> Handle(GetAdUnlockSessionQuery request, CancellationToken cancellationToken)
    {
        var session = await sessions.GetByIdAsync(request.SessionId, cancellationToken);

        // Another user's session reads as missing, so ids can't be probed.
        return session is null || session.UserId != currentUser.GetRequiredUserId()
            ? MonetizationErrors.SessionNotFound
            : AdUnlockSessionResponse.From(session);
    }
}
