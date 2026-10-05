using FluentValidation;
using Microsoft.Extensions.DependencyInjection;
using MolBhav.Application.Abstractions.Events;
using MolBhav.Application.Common.Behaviors;
using MolBhav.Application.Features.Billing.Activation;
using MolBhav.Application.Features.Monetization;

namespace MolBhav.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        var assembly = typeof(DependencyInjection).Assembly;

        services.AddMediatR(config =>
        {
            config.RegisterServicesFromAssembly(assembly);

            // Registration order == execution order (outermost first).
            config.AddOpenBehavior(typeof(RequestLoggingBehavior<,>));
            config.AddOpenBehavior(typeof(ValidationBehavior<,>));
            config.AddOpenBehavior(typeof(UnitOfWorkBehavior<,>));
        });

        services.AddValidatorsFromAssembly(assembly, ServiceLifetime.Scoped, includeInternalTypes: true);

        services.AddDomainEventHandlers(assembly);

        services.AddScoped<SubscriptionActivationService>();
        services.AddScoped<IEntitlementService, EntitlementService>();
        services.AddScoped<Features.Promotions.Admin.CampaignInputResolver>();
        services.AddScoped<Features.Ingestion.Common.IngestionRecordWriter>();

        return services;
    }

    /// <summary>Registers every closed <see cref="IDomainEventHandler{TEvent}"/> implementation as scoped.</summary>
    private static void AddDomainEventHandlers(this IServiceCollection services, System.Reflection.Assembly assembly)
    {
        var openHandler = typeof(IDomainEventHandler<>);

        var registrations = assembly.DefinedTypes
            .Where(t => t is { IsClass: true, IsAbstract: false, IsGenericTypeDefinition: false })
            .SelectMany(t => t.ImplementedInterfaces
                .Where(i => i.IsGenericType && i.GetGenericTypeDefinition() == openHandler)
                .Select(i => (Service: i, Implementation: t.AsType())));

        foreach (var (service, implementation) in registrations)
        {
            services.AddScoped(service, implementation);
        }
    }
}
