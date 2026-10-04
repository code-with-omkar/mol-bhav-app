using MolBhav.Domain.Promotions;

namespace MolBhav.UnitTests.Promotions;

public sealed class CampaignCreativeTests
{
    [Fact]
    public void Create_Valid_TrimsText()
    {
        var creative = CampaignCreative.Create(" Title ", " Body ", " Go ", "https://example.com/a", "https://cdn.example.com/i.png");

        Assert.True(creative.IsSuccess);
        Assert.Equal("Title", creative.Value.Title);
        Assert.Equal("Go", creative.Value.CtaLabel);
        Assert.NotNull(creative.Value.ImageUrl);
    }

    [Theory]
    [InlineData("http://example.com/a")]
    [InlineData("javascript:alert(1)")]
    [InlineData("intent://scan/#Intent;scheme=zxing;end")]
    [InlineData("example.com/a")]
    [InlineData("")]
    public void Create_NonHttpsCtaUrl_Fails(string url) =>
        Assert.Equal("Campaign.CtaUrlInvalid", CampaignCreative.Create("t", "b", "c", url, null).Error.Code);

    [Fact]
    public void Create_NonHttpsImage_Fails() =>
        Assert.Equal(
            "Campaign.ImageUrlInvalid",
            CampaignCreative.Create("t", "b", "c", "https://example.com", "http://example.com/i.png").Error.Code);

    [Fact]
    public void Create_TitleTooLong_Fails() =>
        Assert.Equal(
            "Campaign.TitleInvalid",
            CampaignCreative.Create(new string('a', CampaignCreative.TitleMaxLength + 1), "b", "c", "https://example.com", null).Error.Code);

    [Fact]
    public void Create_EmptyBody_Fails() =>
        Assert.Equal("Campaign.BodyInvalid", CampaignCreative.Create("t", "  ", "c", "https://example.com", null).Error.Code);

    [Fact]
    public void Create_KeepsEscapesInStoredUrl()
    {
        var creative = CampaignCreative.Create("t", "b", "c", "https://example.com/?q=a%26b&p=x%2Fy", null).Value;

        Assert.Equal("https://example.com/?q=a%26b&p=x%2Fy", creative.CtaUrl.AbsoluteUri);
    }
}
