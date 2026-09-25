namespace MolBhav.Domain.Catalog;

/// <summary>
/// What a unit measures. Conversions are only defined within one dimension; each has one base unit that
/// <see cref="UnitOfMeasure.ToBaseFactor"/> is expressed in.
/// </summary>
public enum MeasureDimension
{
    /// <summary>Base: kilogram.</summary>
    Mass = 0,

    /// <summary>Base: cubic metre.</summary>
    Volume = 1,

    /// <summary>Base: one piece.</summary>
    Count = 2,

    /// <summary>Base: metre.</summary>
    Length = 3,

    /// <summary>Base: square metre.</summary>
    Area = 4,
}
