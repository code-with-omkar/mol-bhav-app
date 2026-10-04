using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Abstractions.Promotions;
using MolBhav.Application.Features.Promotions.GetPromotion;
using MolBhav.Application.Features.Promotions.Models;
using MolBhav.Domain.Promotions;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Promotions;

public sealed class GetPromotionQueryHandlerTests
{
    private static readonly DateTimeOffset Now = new(2026, 10, 4, 6, 0, 0, TimeSpan.Zero);
    private static readonly Guid UserId = Guid.NewGuid();

    private readonly IPromotionReadService _reads = Substitute.For<IPromotionReadService>();
    private readonly ICurrentUser _user = Substitute.For<ICurrentUser>();
    private readonly GetPromotionQueryHandler _handler;

    public GetPromotionQueryHandlerTests()
    {
        _user.GetRequiredUserId().Returns(UserId);
        _handler = new GetPromotionQueryHandler(_reads, _user, new FixedTimeProvider(Now));
    }

    [Fact]
    public async Task Handle_ProUser_ReturnsEmptySlotWithoutQuerying()
    {
        _user.SubscriptionTier.Returns("Pro");

        var result = await _handler.Handle(new GetPromotionQuery(PromotionPlacement.HomeFeed), CancellationToken.None);

        Assert.Null(result.Value.Promotion);
        await _reads.DidNotReceiveWithAnyArgs().FindForUserAsync(default, default, default, default, default);
    }

    [Fact]
    public async Task Handle_FreeUser_ReturnsMatchedCampaign()
    {
        _user.SubscriptionTier.Returns(SubscriptionTiers.Free);
        var promotion = new PromotionResponse(Guid.NewGuid(), "Kisan", "t", "b", "Go", "https://example.com", null);
        _reads.FindForUserAsync(UserId, PromotionPlacement.MandiPrices, Now, new DateOnly(2026, 10, 4), Arg.Any<CancellationToken>())
            .Returns(promotion);

        var result = await _handler.Handle(new GetPromotionQuery(PromotionPlacement.MandiPrices), CancellationToken.None);

        Assert.Same(promotion, result.Value.Promotion);
    }

    [Fact]
    public async Task Handle_NothingBooked_ReturnsEmptySlot()
    {
        _user.SubscriptionTier.Returns(SubscriptionTiers.Free);

        var result = await _handler.Handle(new GetPromotionQuery(PromotionPlacement.HomeFeed), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Null(result.Value.Promotion);
    }
}
