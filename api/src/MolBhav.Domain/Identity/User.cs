using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Exceptions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Identity.Events;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Identity;

/// <summary>
/// A MolBhav account (BRD §7). Identified by mobile number, not email/password — the only credential is
/// possession of the phone (OTP). Owns its <see cref="UserProfile"/> and procurement <see cref="Categories"/>;
/// subscription tier and preferred language live here because every request (JWT claims) needs them.
/// </summary>
public sealed class User : AggregateRoot<Guid>, IAuditableEntity, ISoftDeletable
{
    public const int MaxCategories = 10;

    private readonly List<UserProfileCategory> _categories = [];

    private User(Guid id, PhoneNumber phoneNumber)
        : base(id)
    {
        PhoneNumber = phoneNumber;
        PreferredLanguage = LanguageCode.English;
        Status = UserStatus.Active;
        SubscriptionTier = SubscriptionTier.Free;
        Role = UserRole.User;
        Profile = new UserProfile();
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private User()
    {
        PhoneNumber = null!;
        PreferredLanguage = null!;
        Profile = null!;
    }

    public PhoneNumber PhoneNumber { get; private set; }

    public LanguageCode PreferredLanguage { get; private set; }

    public UserStatus Status { get; private set; }

    public SubscriptionTier SubscriptionTier { get; private set; }

    public UserRole Role { get; private set; }

    public DateTimeOffset? LastLoginAtUtc { get; private set; }

    public UserProfile Profile { get; private set; }

    /// <summary>Procurement categories the user operates in (BRD §6/§7 — one or more).</summary>
    public IReadOnlyCollection<UserProfileCategory> Categories => _categories.AsReadOnly();

    /// <summary>True once the onboarding screen has been completed (at least one category chosen).</summary>
    public bool IsOnboarded => _categories.Count > 0;

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public bool IsDeleted { get; private set; }

    public DateTimeOffset? DeletedAtUtc { get; private set; }

    public Guid? DeletedBy { get; private set; }

    /// <summary>Just-in-time registration: the first successful OTP verification for a phone number creates the account.</summary>
    public static User Register(PhoneNumber phoneNumber)
    {
        ArgumentNullException.ThrowIfNull(phoneNumber);

        var user = new User(Guid.CreateVersion7(), phoneNumber);
        user.RaiseDomainEvent(new UserRegisteredDomainEvent(user.Id, phoneNumber.Masked));
        return user;
    }

    public void RecordLogin(DateTimeOffset nowUtc) => LastLoginAtUtc = nowUtc;

    /// <summary>Replaces the profile and category selection in one step (the onboarding/edit-profile screen submits all fields together).</summary>
    public void UpdateProfile(
        string? businessType,
        string? state,
        string? district,
        LanguageCode preferredLanguage,
        IReadOnlyCollection<ProcurementCategoryCode> categories)
    {
        ArgumentNullException.ThrowIfNull(preferredLanguage);
        ArgumentNullException.ThrowIfNull(categories);

        var distinct = categories.DistinctBy(c => c.Value, StringComparer.Ordinal).ToArray();
        if (distinct.Length > MaxCategories)
        {
            throw new DomainException(
                "User.TooManyCategories",
                $"A user can operate in at most {MaxCategories} procurement categories.");
        }

        PreferredLanguage = preferredLanguage;
        Profile.Update(businessType, state, district);

        // Diff rather than clear-and-re-add: unchanged rows stay Unchanged, so EF issues only the real INSERT/DELETEs
        // instead of deleting and re-inserting the same composite key in one SaveChanges.
        var requested = distinct.Select(c => c.Value).ToHashSet(StringComparer.Ordinal);
        _categories.RemoveAll(existing => !requested.Contains(existing.CategoryCode.Value));

        var existingCodes = _categories.Select(c => c.CategoryCode.Value).ToHashSet(StringComparer.Ordinal);
        _categories.AddRange(distinct
            .Where(code => !existingCodes.Contains(code.Value))
            .Select(UserProfileCategory.For));
    }
}
