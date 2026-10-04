using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Localization;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Application.Features.Catalog;
using MolBhav.Domain.Common.Results;

namespace MolBhav.Application.Features.Identity.GetProfile;

internal sealed class GetProfileQueryHandler(
    IUserProfileReadService readService,
    ICurrentUser currentUser,
    ILanguageContext languageContext)
    : IQueryHandler<GetProfileQuery, UserProfileResponse>
{
    public async Task<Result<UserProfileResponse>> Handle(GetProfileQuery request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var profile = await readService.GetByUserIdAsync(userId, CatalogLanguage.From(languageContext), cancellationToken);

        if (profile is null)
        {
            return Error.NotFound("User.NotFound", "User profile not found.");
        }

        return new UserProfileResponse(
            profile.UserId,
            profile.PhoneNumberMasked,
            profile.DisplayName,
            profile.PreferredLanguage,
            profile.SubscriptionTier,
            profile.BusinessType,
            profile.State,
            profile.District,
            profile.BusinessType,
            profile.StateId,
            profile.StateCode,
            profile.StateName,
            profile.DistrictId,
            profile.DistrictName,
            profile.Categories,
            [.. profile.CategoryDetails.Select(c => new ProfileCategoryResponse(c.Code, c.Name))],
            profile.PushEnabled,
            profile.WhatsAppEnabled,
            profile.LastLoginAtUtc,
            profile.CreatedAtUtc,
            currentUser.IsInRole(Roles.Admin));
    }
}
