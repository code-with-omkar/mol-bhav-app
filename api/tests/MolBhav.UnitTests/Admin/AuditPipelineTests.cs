using MediatR;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application;
using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Data;
using MolBhav.Application.Abstractions.FeatureSwitches;
using MolBhav.Application.Features.FeatureSwitches.GetFeatureSwitches;
using MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;
using MolBhav.Domain.Audit;
using MolBhav.Domain.FeatureSwitches;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Admin;

/// <summary>
/// The audit entry must come out of the real MediatR pipeline: an admin's marked command writes one inside the unit of
/// work, and anything else (a query, a failed command, a user-less job) does not.
/// </summary>
public sealed class AuditPipelineTests
{
    private static readonly Guid Admin = Guid.CreateVersion7();

    private readonly IAuditEntryRepository _entries = Substitute.For<IAuditEntryRepository>();
    private readonly IFeatureSwitchRepository _switches = Substitute.For<IFeatureSwitchRepository>();
    private readonly ICurrentUser _user = Substitute.For<ICurrentUser>();
    private readonly FakeUnitOfWork _unitOfWork = new();

    private ServiceProvider Provider()
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddApplication();
        services.AddSingleton(_entries);
        services.AddSingleton(_switches);
        services.AddSingleton(_user);
        services.AddSingleton<IUnitOfWork>(_unitOfWork);
        services.AddSingleton<TimeProvider>(new FixedTimeProvider(new DateTimeOffset(2026, 11, 1, 6, 0, 0, TimeSpan.Zero)));
        return services.BuildServiceProvider();
    }

    [Fact]
    public async Task An_admins_command_is_recorded_inside_the_unit_of_work()
    {
        _user.UserId.Returns(Admin);
        _switches.GetByFeatureAsync(AppFeature.Ads, Arg.Any<CancellationToken>()).Returns((FeatureSwitch?)null);
        await using var provider = Provider();

        var result = await provider.GetRequiredService<ISender>().Send(new SetFeatureSwitchCommand(AppFeature.Ads, false));

        Assert.True(result.IsSuccess);
        _entries.Received(1).Add(Arg.Is<AuditEntry>(e => e.ActorUserId == Admin && e.Action == "Feature.Set" && e.Target == "Ads"));
        // Saved together with the change, in the one transaction.
        Assert.Equal(1, _unitOfWork.Transactions);
        Assert.Equal(1, _unitOfWork.Saves);
    }

    [Fact]
    public async Task A_command_run_with_no_user_writes_no_entry()
    {
        _user.UserId.Returns((Guid?)null);
        _switches.GetByFeatureAsync(AppFeature.Ads, Arg.Any<CancellationToken>()).Returns((FeatureSwitch?)null);
        await using var provider = Provider();

        await provider.GetRequiredService<ISender>().Send(new SetFeatureSwitchCommand(AppFeature.Ads, false));

        _entries.DidNotReceive().Add(Arg.Any<AuditEntry>());
    }

    [Fact]
    public async Task A_query_writes_no_entry()
    {
        _user.UserId.Returns(Admin);
        _switches.ListAsync(Arg.Any<CancellationToken>()).Returns([]);
        await using var provider = Provider();

        var result = await provider.GetRequiredService<ISender>().Send(new GetFeatureSwitchesQuery());

        Assert.True(result.IsSuccess);
        _entries.DidNotReceive().Add(Arg.Any<AuditEntry>());
    }

    [Fact]
    public async Task A_command_refused_by_validation_writes_no_entry()
    {
        _user.UserId.Returns(Admin);
        await using var provider = Provider();

        // Validation stops the request before it reaches the handler (the API turns this into a 400).
        await Assert.ThrowsAsync<MolBhav.Application.Common.Exceptions.RequestValidationException>(
            () => provider.GetRequiredService<ISender>().Send(new SetFeatureSwitchCommand((AppFeature)99, true)));

        _entries.DidNotReceive().Add(Arg.Any<AuditEntry>());
        Assert.Equal(0, _unitOfWork.Transactions);
    }

    /// <summary>Runs the operation straight through, counting transactions and saves.</summary>
    private sealed class FakeUnitOfWork : IUnitOfWork
    {
        public int Transactions { get; private set; }

        public int Saves { get; private set; }

        public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            Saves++;
            return Task.FromResult(1);
        }

        public async Task<TResult> ExecuteInTransactionAsync<TResult>(
            Func<CancellationToken, Task<TResult>> operation,
            Func<TResult, bool> shouldCommit,
            CancellationToken cancellationToken = default)
        {
            Transactions++;
            return await operation(cancellationToken);
        }
    }
}
