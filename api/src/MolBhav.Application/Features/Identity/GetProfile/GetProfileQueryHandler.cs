using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Identity.GetProfile;

internal sealed class GetProfileQueryHandler(IUserProfileReadService readService, ICurrentUser currentUser)
    : IQueryHandler<GetProfileQuery, UserProfileResponse>
{
    public async Task<Result<UserProfileResponse>> Handle(GetProfileQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var profile = await readService.GetByUserIdAsync(userId, cancellationToken);

        if (profile is null)
        {
            return Error.NotFound("User.NotFound", "User profile not found.");
        }

        return new UserProfileResponse(
            profile.UserId,
            profile.PhoneNumberMasked,
            profile.PreferredLanguage,
            profile.SubscriptionTier,
            profile.BusinessType,
            profile.State,
            profile.District,
            profile.Categories,
            profile.LastLoginAtUtc,
            profile.CreatedAtUtc);
    }
}
