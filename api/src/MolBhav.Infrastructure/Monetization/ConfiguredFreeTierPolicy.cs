using Microsoft.Extensions.Options;
using MolBhav.Application.Abstractions.Monetization;
using MolBhav.Domain.Monetization;

namespace MolBhav.Infrastructure.Monetization;

/// <summary>Singleton: the rules are fixed for the process lifetime (options are validated on start).</summary>
internal sealed class ConfiguredFreeTierPolicy(IOptions<MonetizationOptions> options) : IFreeTierPolicy
{
    public FreeTierLimits Limits { get; } = options.Value.ToLimits();
}
