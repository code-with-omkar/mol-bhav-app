using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Catalog;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Abstractions.Messaging;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Application.Features.Identity.UpdateProfile;

internal sealed class UpdateProfileCommandHandler(
    IUserRepository users,
    IProcurementCategoryLookup categoryLookup,
    ICurrentUser currentUser)
    : ICommandHandler<UpdateProfileCommand, UpdateProfileResponse>
{
    public async Task<Result<UpdateProfileResponse>> Handle(UpdateProfileCommand request, CancellationToken cancellationToken)
    {
        var userId = currentUser.GetRequiredUserId();
        var user = await users.GetByIdAsync(userId, cancellationToken);
        if (user is null)
        {
            return Error.NotFound("User.NotFound", "User not found.");
        }

        var languageResult = LanguageCode.Create(request.PreferredLanguage);
        if (languageResult.IsFailure)
        {
            return Result.Failure<UpdateProfileResponse>(languageResult.Error);
        }

        var categories = new List<ProcurementCategoryCode>(request.Categories.Count);
        foreach (var code in request.Categories)
        {
            var categoryResult = ProcurementCategoryCode.Create(code);
            if (categoryResult.IsFailure)
            {
                return Result.Failure<UpdateProfileResponse>(categoryResult.Error);
            }

            categories.Add(categoryResult.Value);
        }

        // Shape is validated by the value object; existence/active status belongs to the Catalog module.
        var requestedCodes = categories.Select(c => c.Value).Distinct(StringComparer.Ordinal).ToArray();
        var activeCodes = await categoryLookup.GetActiveCodesAsync(requestedCodes, cancellationToken);
        var unknown = requestedCodes.FirstOrDefault(code => !activeCodes.Contains(code));
        if (unknown is not null)
        {
            return Error.Validation("ProcurementCategory.NotFound", $"Category '{unknown}' does not exist or is not available.");
        }

        user.UpdateProfile(request.BusinessType, request.State, request.District, languageResult.Value, categories);

        return new UpdateProfileResponse(
            user.Id,
            user.PreferredLanguage.Value,
            user.Categories.Select(c => c.CategoryCode.Value).ToArray());
    }
}
