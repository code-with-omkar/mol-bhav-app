using MolBhav.Application.Abstractions.AppVersions;
using MolBhav.Application.Features.AppVersions.GetAppVersionPolicy;
using MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;
using MolBhav.Domain.AppVersions;

namespace MolBhav.UnitTests.Admin;

public sealed class AppVersionPolicyTests
{
    private readonly IAppVersionPolicyRepository _policies = Substitute.For<IAppVersionPolicyRepository>();

    [Theory]
    [InlineData("1", "1.0.0")]
    [InlineData("1.2", "1.2.0")]
    [InlineData("1.2.3", "1.2.3")]
    [InlineData(" 2.10.0 ", "2.10.0")]
    [InlineData("01.02.03", "1.2.3")]
    public void A_version_is_written_as_major_minor_patch(string input, string expected)
    {
        var result = AppVersionPolicy.Create(input, null);

        Assert.True(result.IsSuccess);
        Assert.Equal(expected, result.Value.MinimumVersion);
    }

    [Theory]
    [InlineData("abc")]
    [InlineData("1.2.3.4")]
    [InlineData("1.2.3+4")]
    [InlineData("v1.2")]
    [InlineData("1..2")]
    [InlineData("-1")]
    public void A_version_that_is_not_dotted_numbers_is_refused(string input)
    {
        Assert.Equal("AppVersion.VersionInvalid", AppVersionPolicy.Create(input, null).Error.Code);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void No_version_means_no_minimum(string? input)
    {
        var policy = AppVersionPolicy.Create(input, null).Value;

        Assert.Null(policy.MinimumVersion);
    }

    [Fact]
    public void The_update_link_must_be_a_web_address()
    {
        Assert.True(AppVersionPolicy.Create("1.0.0", "https://play.google.com/store/apps/details?id=com.molbhav").IsSuccess);
        Assert.Equal("AppVersion.UrlInvalid", AppVersionPolicy.Create("1.0.0", "javascript:alert(1)").Error.Code);
        Assert.Equal("AppVersion.UrlInvalid", AppVersionPolicy.Create("1.0.0", "not a link").Error.Code);
        Assert.Equal("AppVersion.UrlInvalid", AppVersionPolicy.Create("1.0.0", "ftp://example.com/app").Error.Code);
        Assert.Null(AppVersionPolicy.Create("1.0.0", "  ").Value.UpdateUrl);
    }

    [Fact]
    public void An_update_replaces_both_values_and_can_clear_the_minimum()
    {
        var policy = AppVersionPolicy.Create("1.2.0", "https://example.com/a").Value;

        Assert.True(policy.Update(null, null).IsSuccess);

        Assert.Null(policy.MinimumVersion);
        Assert.Null(policy.UpdateUrl);
        Assert.Equal("AppVersion.VersionInvalid", policy.Update("x", null).Error.Code);
    }

    [Fact]
    public async Task The_first_save_creates_the_policy_and_later_saves_edit_it()
    {
        _policies.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns((AppVersionPolicy?)null);
        var handler = new SetAppVersionPolicyCommandHandler(_policies);

        Assert.True((await handler.Handle(new("1.1", null), CancellationToken.None)).IsSuccess);
        _policies.Received(1).Add(Arg.Is<AppVersionPolicy>(p => p.MinimumVersion == "1.1.0"));

        var existing = AppVersionPolicy.Create("1.1", null).Value;
        _policies.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns(existing);

        Assert.True((await handler.Handle(new("2.0.0", "https://example.com"), CancellationToken.None)).IsSuccess);
        Assert.Equal("2.0.0", existing.MinimumVersion);
        _policies.Received(1).Add(Arg.Any<AppVersionPolicy>());
    }

    [Fact]
    public async Task A_bad_version_is_not_saved()
    {
        _policies.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns((AppVersionPolicy?)null);

        var result = await new SetAppVersionPolicyCommandHandler(_policies).Handle(new("oops", null), CancellationToken.None);

        Assert.True(result.IsFailure);
        _policies.DidNotReceive().Add(Arg.Any<AppVersionPolicy>());
    }

    [Fact]
    public async Task The_app_is_told_there_is_no_minimum_until_one_is_set()
    {
        var handler = new GetAppVersionPolicyQueryHandler(_policies);

        _policies.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns((AppVersionPolicy?)null);
        var none = (await handler.Handle(new GetAppVersionPolicyQuery(), CancellationToken.None)).Value;
        Assert.Null(none.MinimumVersion);
        Assert.Null(none.UpdateUrl);

        _policies.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns(AppVersionPolicy.Create("1.4", "https://example.com/u").Value);
        var set = (await handler.Handle(new GetAppVersionPolicyQuery(), CancellationToken.None)).Value;
        Assert.Equal("1.4.0", set.MinimumVersion);
        Assert.Equal("https://example.com/u", set.UpdateUrl);
    }
}
