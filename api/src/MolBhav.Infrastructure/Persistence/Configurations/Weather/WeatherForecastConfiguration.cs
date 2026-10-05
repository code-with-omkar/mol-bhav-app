using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using MolBhav.Domain.Identity;
using MolBhav.Domain.Weather;
using MolBhav.Infrastructure.Weather;

namespace MolBhav.Infrastructure.Persistence.Configurations.Weather;

internal sealed class WeatherForecastConfiguration : IEntityTypeConfiguration<WeatherForecast>
{
    public const string TableName = "imd_forecasts";
    public const string QualifiedTableName = Schemas.Weather + "." + TableName;

    public void Configure(EntityTypeBuilder<WeatherForecast> builder)
    {
        builder.ToTable(TableName, Schemas.Weather);

        builder.ConfigureAggregateRoot()
            .ConfigureAuditing();

        builder.HasOne<User>().WithMany().HasForeignKey(f => f.UserId).OnDelete(DeleteBehavior.Cascade).IsRequired();

        builder.Property(f => f.ForecastDate).IsRequired();
        builder.Property(f => f.StationCode).HasMaxLength(WeatherForecast.StationCodeMaxLength).IsRequired();
        builder.Property(f => f.FetchedAtUtc).IsRequired();

        // The whole 7-day array is one jsonb value, read and replaced as a unit. The comparer lets EF see an in-place
        // Replace() as a change (the converted value is a reference type).
        builder.Property(f => f.Days)
            .HasColumnType("jsonb")
            .HasConversion(
                days => WeatherDaysJson.Serialize(days),
                json => WeatherDaysJson.Deserialize(json),
                new ValueComparer<IReadOnlyList<WeatherDay>>(
                    (a, b) => a!.SequenceEqual(b!),
                    days => days.Aggregate(0, (hash, day) => HashCode.Combine(hash, day)),
                    days => days.ToArray()))
            .IsRequired();

        // No archive: a user has exactly one current forecast, so user_id alone is unique (this also covers the
        // (user_id, forecast_date) pair). It is the lookup key for both the read and the daily upsert.
        builder.HasIndex(f => f.UserId).IsUnique();
    }
}
