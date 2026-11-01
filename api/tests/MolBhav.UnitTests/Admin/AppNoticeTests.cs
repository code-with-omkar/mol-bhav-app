using MolBhav.Application.Abstractions.AppNotices;
using MolBhav.Application.Features.AppNotices.GetAppNotice;
using MolBhav.Application.Features.AppNotices.SetAppNotice;
using MolBhav.Domain.AppNotices;

namespace MolBhav.UnitTests.Admin;

public sealed class AppNoticeTests
{
    private readonly IAppNoticeRepository _notices = Substitute.For<IAppNoticeRepository>();

    [Fact]
    public void A_notice_that_is_on_needs_a_message()
    {
        var result = AppNotice.Create(true, NoticeSeverity.Info, "   ");

        Assert.Equal("AppNotice.MessageRequired", result.Error.Code);
    }

    [Fact]
    public void A_notice_that_is_off_may_have_no_message()
    {
        var result = AppNotice.Create(false, NoticeSeverity.Info, null);

        Assert.True(result.IsSuccess);
        Assert.False(result.Value.IsActive);
        Assert.Equal(string.Empty, result.Value.Message);
    }

    [Fact]
    public void The_message_is_trimmed_and_limited()
    {
        Assert.Equal("Back at 6 pm.", AppNotice.Create(true, NoticeSeverity.Maintenance, "  Back at 6 pm.  ").Value.Message);
        Assert.Equal(
            "AppNotice.MessageTooLong",
            AppNotice.Create(true, NoticeSeverity.Info, new string('x', AppNotice.MessageMaxLength + 1)).Error.Code);
    }

    [Fact]
    public void An_unknown_type_is_refused()
    {
        var result = AppNotice.Create(true, (NoticeSeverity)99, "Hello");

        Assert.Equal("AppNotice.SeverityInvalid", result.Error.Code);
    }

    [Fact]
    public void Switching_a_notice_off_keeps_its_text()
    {
        var notice = AppNotice.Create(true, NoticeSeverity.Warning, "Prices are late.").Value;

        Assert.True(notice.Update(false, NoticeSeverity.Warning, "Prices are late.").IsSuccess);

        Assert.False(notice.IsActive);
        Assert.Equal("Prices are late.", notice.Message);
    }

    [Fact]
    public async Task The_first_save_creates_the_notice_and_later_saves_edit_it()
    {
        _notices.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns((AppNotice?)null);
        var handler = new SetAppNoticeCommandHandler(_notices);

        var first = await handler.Handle(new(true, NoticeSeverity.Info, "Maintenance tonight."), CancellationToken.None);

        Assert.True(first.IsSuccess);
        _notices.Received(1).Add(Arg.Is<AppNotice>(n => n.Message == "Maintenance tonight." && n.IsActive));

        var existing = AppNotice.Create(true, NoticeSeverity.Info, "Maintenance tonight.").Value;
        _notices.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns(existing);

        var second = await handler.Handle(new(false, NoticeSeverity.Info, "Maintenance tonight."), CancellationToken.None);

        Assert.True(second.IsSuccess);
        Assert.False(existing.IsActive);
        _notices.Received(1).Add(Arg.Any<AppNotice>());
    }

    [Fact]
    public async Task Users_get_nothing_to_show_when_there_is_no_notice_or_it_is_off()
    {
        var handler = new GetAppNoticeQueryHandler(_notices);

        _notices.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns((AppNotice?)null);
        Assert.False((await handler.Handle(new GetAppNoticeQuery(), CancellationToken.None)).Value.IsActive);

        var off = AppNotice.Create(false, NoticeSeverity.Warning, "Old news").Value;
        _notices.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns(off);

        var forUsers = (await handler.Handle(new GetAppNoticeQuery(), CancellationToken.None)).Value;
        Assert.False(forUsers.IsActive);
        Assert.Equal(string.Empty, forUsers.Message);

        var forAdmin = (await handler.Handle(new GetAppNoticeQuery(ForEditing: true), CancellationToken.None)).Value;
        Assert.False(forAdmin.IsActive);
        Assert.Equal("Old news", forAdmin.Message);
        Assert.Equal(NoticeSeverity.Warning, forAdmin.Severity);
    }

    [Fact]
    public async Task An_active_notice_is_shown_as_saved()
    {
        var notice = AppNotice.Create(true, NoticeSeverity.Maintenance, "Back at 6 pm.").Value;
        _notices.GetCurrentAsync(Arg.Any<CancellationToken>()).Returns(notice);

        var response = (await new GetAppNoticeQueryHandler(_notices).Handle(new GetAppNoticeQuery(), CancellationToken.None)).Value;

        Assert.True(response.IsActive);
        Assert.Equal(NoticeSeverity.Maintenance, response.Severity);
        Assert.Equal("Back at 6 pm.", response.Message);
    }
}
