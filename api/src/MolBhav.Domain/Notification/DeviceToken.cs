using MolBhav.Domain.Common.Abstractions;
using MolBhav.Domain.Common.Primitives;

namespace MolBhav.Domain.Notification;

/// <summary>FCM/APNS device token registered by a user on a specific platform.</summary>
public sealed class DeviceToken : AggregateRoot<Guid>, IAuditableEntity
{
    public const int TokenMaxLength = 500;

    private DeviceToken(Guid id, Guid userId, string token, DevicePlatform platform)
        : base(id)
    {
        UserId = userId;
        Token = token;
        Platform = platform;
    }

    /// <summary>Required by EF Core for materialisation.</summary>
    private DeviceToken()
    {
        Token = string.Empty;
    }

    public Guid UserId { get; private set; }

    public string Token { get; private set; }

    public DevicePlatform Platform { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public Guid? CreatedBy { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public Guid? UpdatedBy { get; private set; }

    public static DeviceToken Create(Guid userId, string token, DevicePlatform platform)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(token);
        return new DeviceToken(Guid.CreateVersion7(), userId, token.Trim(), platform);
    }
}
