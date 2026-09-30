using System.Data;
using Dapper;

namespace MolBhav.Infrastructure.Persistence.Read;

/// <summary>Dapper has no built-in mapping for <see cref="DateOnly"/>; Npgsql maps it to <c>date</c> directly.</summary>
internal sealed class DateOnlyTypeHandler : SqlMapper.TypeHandler<DateOnly>
{
    public override void SetValue(IDbDataParameter parameter, DateOnly value) => parameter.Value = value;

    public override DateOnly Parse(object value) => value switch
    {
        DateOnly dateOnly => dateOnly,
        DateTime dateTime => DateOnly.FromDateTime(dateTime),
        _ => throw new InvalidCastException($"Cannot convert {value.GetType()} to {nameof(DateOnly)}."),
    };
}
