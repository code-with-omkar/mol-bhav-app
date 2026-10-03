using Microsoft.Extensions.Logging.Abstractions;
using MolBhav.Application.Abstractions.Billing;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Features.Billing.ExpireLapsed;
using MolBhav.Domain.Billing;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;
using static MolBhav.UnitTests.Billing.BillingTestData;

namespace MolBhav.UnitTests.Billing;

public sealed class ExpireLapsedSubscriptionsCommandHandlerTests
{
    private readonly ISubscriptionRepository _subscriptions = Substitute.For<ISubscriptionRepository>();
    private readonly IUserRepository _users = Substitute.For<IUserRepository>();
    private readonly Plan _plan = ProMonthly();

    private ExpireLapsedSubscriptionsCommandHandler CreateHandler(DateTimeOffset now) =>
        new(_subscriptions, _users, new FixedTimeProvider(now), NullLogger<ExpireLapsedSubscriptionsCommandHandler>.Instance);

    private (User User, Subscription Subscription) ActiveProUser(DateTimeOffset activatedAt)
    {
        var user = User.Register(PhoneNumber.Create("9876543210").Value);
        user.SetSubscriptionTier(SubscriptionTier.Pro);
        _users.GetByIdAsync(user.Id, Arg.Any<CancellationToken>()).Returns(user);
        return (user, Active(user.Id, _plan, activatedAt));
    }

    [Fact]
    public async Task Handle_LapsedSubscription_ExpiresItAndDowngradesUser()
    {
        var (user, subscription) = ActiveProUser(Now.AddMonths(-2));
        var now = subscription.ExpiresAtUtc.AddMinutes(1);
        _subscriptions.GetLapsedActiveAsync(now, 200, Arg.Any<CancellationToken>()).Returns(new[] { subscription });

        var result = await CreateHandler(now).Handle(new ExpireLapsedSubscriptionsCommand(200), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(1, result.Value);
        Assert.Equal(SubscriptionStatus.Expired, subscription.Status);
        Assert.Equal(SubscriptionTier.Free, user.SubscriptionTier);
    }

    [Fact]
    public async Task Handle_NothingLapsed_ReturnsZeroAndChangesNothing()
    {
        var (user, _) = ActiveProUser(Now);
        _subscriptions.GetLapsedActiveAsync(Arg.Any<DateTimeOffset>(), Arg.Any<int>(), Arg.Any<CancellationToken>()).Returns(Array.Empty<Subscription>());

        var result = await CreateHandler(Now).Handle(new ExpireLapsedSubscriptionsCommand(200), CancellationToken.None);

        Assert.Equal(0, result.Value);
        Assert.Equal(SubscriptionTier.Pro, user.SubscriptionTier);
    }

    [Fact]
    public async Task Handle_AlreadyExpiredRow_IsSkippedWithoutTouchingTheUser()
    {
        var (user, subscription) = ActiveProUser(Now.AddMonths(-2));
        subscription.Expire();
        _subscriptions.GetLapsedActiveAsync(Arg.Any<DateTimeOffset>(), Arg.Any<int>(), Arg.Any<CancellationToken>()).Returns(new[] { subscription });

        var result = await CreateHandler(Now).Handle(new ExpireLapsedSubscriptionsCommand(200), CancellationToken.None);

        Assert.Equal(0, result.Value);
        Assert.Equal(SubscriptionTier.Pro, user.SubscriptionTier);
    }

    [Fact]
    public async Task Handle_PassesTheBatchSizeToTheRepository()
    {
        _subscriptions.GetLapsedActiveAsync(Arg.Any<DateTimeOffset>(), Arg.Any<int>(), Arg.Any<CancellationToken>()).Returns(Array.Empty<Subscription>());

        await CreateHandler(Now).Handle(new ExpireLapsedSubscriptionsCommand(50), CancellationToken.None);

        await _subscriptions.Received(1).GetLapsedActiveAsync(Now, 50, Arg.Any<CancellationToken>());
    }
}
