using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using MolBhav.Infrastructure.Persistence.Converters;

namespace MolBhav.Infrastructure.Persistence.Configurations.Identity;

internal sealed class OtpChallengeConfiguration : IEntityTypeConfiguration<OtpChallenge>
{
    public const string TableName = "otp_challenges";

    /// <summary>Hex-encoded SHA-256 (64 chars).</summary>
    private const int CodeHashLength = 64;

    public void Configure(EntityTypeBuilder<OtpChallenge> builder)
    {
        builder.ToTable(TableName, Schemas.Identity);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.Property(c => c.PhoneNumber)
            .HasConversion(ValueObjectConverters.PhoneNumberConverter)
            .HasMaxLength(PhoneNumber.MaxLength)
            .IsRequired();

        builder.Property(c => c.CodeHash)
            .HasMaxLength(CodeHashLength)
            .IsFixedLength()
            .IsRequired();

        builder.Property(c => c.ExpiresAtUtc).IsRequired();
        builder.Property(c => c.ConsumedAtUtc);
        builder.Property(c => c.AttemptCount).IsRequired();

        // Every request/verify looks up "latest challenge for this phone": equality on phone, newest first.
        // UUIDv7 ids are time-ordered, so (phone_number, id DESC) serves both the filter and the ordering
        // without a separate created_at index.
        builder.HasIndex(c => new { c.PhoneNumber, c.Id })
            .IsDescending(false, true);
    }
}
