using System.Globalization;
using MolBhav.Api;
using MolBhav.Api.Setup;
using MolBhav.Application;
using MolBhav.Infrastructure;
using Serilog;

Log.Logger = new LoggerConfiguration()
    .WriteTo.Console(formatProvider: CultureInfo.InvariantCulture)
    .CreateBootstrapLogger();

try
{
    var builder = WebApplication.CreateBuilder(args);

    builder.WebHost.ConfigureKestrel(options => options.AddServerHeader = false);

    builder.Services.AddSerilog((services, logger) => logger
        .ReadFrom.Configuration(builder.Configuration)
        .ReadFrom.Services(services)
        .Enrich.FromLogContext());

    builder.Services
        .AddApplication()
        .AddInfrastructure(builder.Configuration, builder.Environment)
        .AddPresentation(builder.Configuration, builder.Environment);


    var app = builder.Build();

    app.UseCors(CorsSettings.PolicyName);

    // Enable body buffering for the webhook endpoint so the raw body can be read for HMAC verification.
    app.Use(async (ctx, next) =>
    {
        if (ctx.Request.Path.StartsWithSegments("/api/v1/billing/webhook"))
        {
            ctx.Request.EnableBuffering();
        }
        await next();
    });

    app.UsePresentation();
    
    await app.RunAsync();
}
catch (Exception ex) when (ex is not HostAbortedException)
{
    Log.Fatal(ex, "MolBhav API terminated unexpectedly");
    throw;
}
finally
{
    await Log.CloseAndFlushAsync();
}

/// <summary>Exposed for <c>WebApplicationFactory&lt;Program&gt;</c> integration tests.</summary>
public partial class Program
{
}
