using MolBhav.Domain.Promotions;

namespace MolBhav.UnitTests.Promotions;

public sealed class AdvertiserTests
{
    [Fact]
    public void Create_Valid_NormalisesOptionalFields()
    {
        var advertiser = Advertiser.Create(" Kisan Seeds ", "  ", null, "27abcde1234f1z5").Value;

        Assert.Equal("Kisan Seeds", advertiser.Name);
        Assert.Null(advertiser.ContactName);
        Assert.Equal("27ABCDE1234F1Z5", advertiser.Gstin);
    }

    [Fact]
    public void Create_MissingName_Fails() =>
        Assert.Equal("Advertiser.NameInvalid", Advertiser.Create(" ", null, null, null).Error.Code);

    [Theory]
    [InlineData("27ABCDE1234F1Z")]
    [InlineData("27ABCDE1234F1Z5X")]
    [InlineData("27ABCDE1234F1Z-")]
    public void Create_BadGstin_Fails(string gstin) =>
        Assert.Equal("Advertiser.GstinInvalid", Advertiser.Create("Kisan", null, null, gstin).Error.Code);

    [Fact]
    public void Update_Invalid_KeepsPreviousValues()
    {
        var advertiser = Advertiser.Create("Kisan", null, null, null).Value;

        var result = advertiser.Update("", "x", null, null);

        Assert.True(result.IsFailure);
        Assert.Equal("Kisan", advertiser.Name);
    }
}
