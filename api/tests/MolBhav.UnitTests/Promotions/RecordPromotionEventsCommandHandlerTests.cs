using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Application.Features.Promotions.RecordPromotionEvents;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Promotions;

public sealed class RecordPromotionEventsCommandHandlerTests
{
    // 20:00 UTC on 3 Oct is 01:30 IST on 4 Oct: counts belong to the Indian day.
    private static readonly DateTimeOffset Now = new(2026, 10, 3, 20, 0, 0, TimeSpan.Zero);
    private static readonly Guid UserId = Guid.NewGuid();

    private readonly IPromotionStatsWriter _writer = Substitute.For<IPromotionStatsWriter>();
    private readonly ICurrentUser _user = Substitute.For<ICurrentUser>();
    private readonly RecordPromotionEventsCommandHandler _handler;
    private IReadOnlyList<PromotionDelivery>? _written;

    public RecordPromotionEventsCommandHandlerTests()
    {
        _user.GetRequiredUserId().Returns(UserId);
        _user.SubscriptionTier.Returns(SubscriptionTiers.Free);
        _writer
            .RecordAsync(
                Arg.Any<Guid>(),
                Arg.Any<DateTimeOffset>(),
                Arg.Any<DateOnly>(),
                Arg.Do<IReadOnlyList<PromotionDelivery>>(d => _written = d),
                Arg.Any<CancellationToken>())
            .Returns(Task.CompletedTask);
        _handler = new RecordPromotionEventsCommandHandler(_writer, _user, new FixedTimeProvider(Now));
    }

    private static PromotionEventInput[] Events(Guid campaign, PromotionEventType type, int count) =>
        Enumerable.Range(0, count).Select(_ => new PromotionEventInput(campaign, type)).ToArray();

    [Fact]
    public async Task Handle_GroupsPerCampaign_ForUserOnIstDay()
    {
        var a = Guid.NewGuid();
        var b = Guid.NewGuid();

        var result = await _handler.Handle(
            new RecordPromotionEventsCommand([
                .. Events(a, PromotionEventType.Impression, 2),
                .. Events(a, PromotionEventType.Click, 1),
                .. Events(b, PromotionEventType.Impression, 1),
            ]),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _writer.Received(1).RecordAsync(
            UserId, Now, new DateOnly(2026, 10, 4), Arg.Any<IReadOnlyList<PromotionDelivery>>(), Arg.Any<CancellationToken>());
        Assert.NotNull(_written);
        Assert.Contains(new PromotionDelivery(a, 2, 1), _written);
        Assert.Contains(new PromotionDelivery(b, 1, 0), _written);
    }

    [Fact]
    public async Task Handle_CapsInflatedCounts()
    {
        var a = Guid.NewGuid();

        await _handler.Handle(
            new RecordPromotionEventsCommand([
                .. Events(a, PromotionEventType.Impression, 30),
                .. Events(a, PromotionEventType.Click, 20),
            ]),
            CancellationToken.None);

        var delivery = Assert.Single(_written!);
        Assert.Equal(RecordPromotionEventsCommandHandler.MaxImpressionsPerCampaign, delivery.Impressions);
        Assert.Equal(RecordPromotionEventsCommandHandler.MaxClicksPerCampaign, delivery.Clicks);
    }

    [Fact]
    public async Task Handle_ProUser_IsIgnored()
    {
        _user.SubscriptionTier.Returns("Pro");

        var result = await _handler.Handle(
            new RecordPromotionEventsCommand(Events(Guid.NewGuid(), PromotionEventType.Impression, 1)),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _writer.DidNotReceiveWithAnyArgs().RecordAsync(default, default, default, default!, default);
    }

    [Fact]
    public async Task Handle_OnlyUnknownTypes_WritesNothing()
    {
        var result = await _handler.Handle(
            new RecordPromotionEventsCommand([new PromotionEventInput(Guid.NewGuid(), null)]),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _writer.DidNotReceiveWithAnyArgs().RecordAsync(default, default, default, default!, default);
    }
}
