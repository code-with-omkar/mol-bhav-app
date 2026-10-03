using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Exceptions;
using MolBhav.Domain.Common.Primitives;
using MolBhav.Domain.Identity.Events;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.Domain.Identity;

/// <summary>
/// A MolBhav account (BRD §7). Identified by mobile number. Credentials are configurable (see <c>ILoginMethods</c>):
/// possession of the phone (OTP) and/or a password chosen at registration. Owns its <see cref="UserProfile"/> and procurement <see cref="Categories"/>;
/// subscription tier and preferred language live here because every request (JWT claims) needs them.
/// </summary>
public sealed class User : AggregateRoot<Guid>, IAuditableEntity, ISoftDeletable
{
    public const int MaxCategories = 10;
    public const int DisplayNameMinLength = 2;
    public const int DisplayNameMaxLength = 60;

    /// <summary>Wrong passwords tolerated before the account is temporarily locked (OWASP brute-force control).</summary>
    public const int MaxFailedPasswordAttempts = 5;

    /// <summary>Upper bound for the stored hash string (algorithm id, iterations, salt and digest, Base64).</summary>
    public const int PasswordHashMaxLength = 256;

    /// <summary>How long password login stays blocked after <see cref="MaxFailedPasswordAttempts"/> consecutive failures.</summary>
    public static readonly TimeSpan PasswordLockoutDuration = TimeSpan.FromMinutes(15);

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

    /// <summary>The name the user gave during onboarding; null until set. Shown in greetings, never used for identity.</summary>
    public string? DisplayName { get; private set; }

    public LanguageCode PreferredLanguage { get; private set; }

    public UserStatus Status { get; private set; }

    public SubscriptionTier SubscriptionTier { get; private set; }

    public UserRole Role { get; private set; }

    public DateTimeOffset? LastLoginAtUtc { get; private set; }

    /// <summary>Self-describing password hash (never the plain password); null for OTP-only accounts.</summary>
    public string? PasswordHash { get; private set; }

    /// <summary>Consecutive wrong passwords since the last successful login or lockout.</summary>
    public int FailedPasswordAttempts { get; private set; }

    /// <summary>Password login is refused until this instant; null when not locked.</summary>
    public DateTimeOffset? PasswordLockoutEndsAtUtc { get; private set; }

    public bool HasPassword => PasswordHash is not null;

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

    /// <summary>Registration with a password (free login path, no SMS). Same just-in-time account as <see cref="Register"/>.</summary>
    public static User RegisterWithPassword(PhoneNumber phoneNumber, string passwordHash)
    {
        var user = Register(phoneNumber);
        user.SetPassword(passwordHash);
        return user;
    }

    /// <summary>Any successful login (OTP or password) clears the brute-force counters.</summary>
    public void RecordLogin(DateTimeOffset nowUtc)
    {
        LastLoginAtUtc = nowUtc;
        FailedPasswordAttempts = 0;
        PasswordLockoutEndsAtUtc = null;
    }

    /// <summary>Sets or replaces the password hash; resets the brute-force counters.</summary>
    public void SetPassword(string passwordHash)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);
        if (passwordHash.Length > PasswordHashMaxLength)
        {
            throw new DomainException("User.PasswordHashTooLong", $"A password hash must be at most {PasswordHashMaxLength} characters.");
        }

        PasswordHash = passwordHash;
        FailedPasswordAttempts = 0;
        PasswordLockoutEndsAtUtc = null;
    }

    public bool IsPasswordLockedOut(DateTimeOffset nowUtc) =>
        PasswordLockoutEndsAtUtc is { } endsAt && endsAt > nowUtc;

    /// <summary>
    /// Counts a wrong password. The <see cref="MaxFailedPasswordAttempts"/>th consecutive failure locks password login for
    /// <see cref="PasswordLockoutDuration"/> and restarts the count, so each lockout window allows a fresh, bounded number of tries.
    /// </summary>
    public void RecordFailedPasswordAttempt(DateTimeOffset nowUtc)
    {
        FailedPasswordAttempts++;
        if (FailedPasswordAttempts >= MaxFailedPasswordAttempts)
        {
            PasswordLockoutEndsAtUtc = nowUtc.Add(PasswordLockoutDuration);
            FailedPasswordAttempts = 0;
        }
    }

    public void SetSubscriptionTier(SubscriptionTier tier) => SubscriptionTier = tier;

    /// <summary>Replaces the profile and category selection in one step (the onboarding/edit-profile screen submits all fields together).</summary>
    public void UpdateProfile(
        string? displayName,
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

        var name = NormaliseDisplayName(displayName);
        if (name is not null && name.Length is < DisplayNameMinLength or > DisplayNameMaxLength)
        {
            throw new DomainException(
                "User.DisplayNameLength",
                $"A display name must be {DisplayNameMinLength}–{DisplayNameMaxLength} characters.");
        }

        DisplayName = name;
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

    /// <summary>Trims and collapses inner whitespace runs; blank becomes null.</summary>
    public static string? NormaliseDisplayName(string? value) =>
        string.IsNullOrWhiteSpace(value)
            ? null
            : string.Join(' ', value.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries));
}
