using MolBhav.Domain.Monetization;

namespace MolBhav.Application.Abstractions.Monetization;

/// <summary>The configured free-tier rules (validated at startup by Infrastructure).</summary>
public interface IFreeTierPolicy
{
    FreeTierLimits Limits { get; }
}
