using MediatR;
using MolBhav.Application.Abstractions.Audit;
using MolBhav.Application.Abstractions.Authentication;
using MolBhav.Application.Common.Behaviors;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Application.Features.Admin.SetUserStatus;
using MolBhav.Application.Features.AppNotices.SetAppNotice;
using MolBhav.Application.Features.AppVersions.SetAppVersionPolicy;
using MolBhav.Application.Features.FeatureSwitches.SetFeatureSwitch;
using MolBhav.Application.Features.Market.Admin.ImportFeedMarkets;
using MolBhav.Application.Features.Promotions.Admin.SetCampaignStatus;
using MolBhav.Application.Features.Support.Admin.AddAdminTicketMessage;
using MolBhav.Application.Features.Support.Admin.UpdateTicketStatus;
using MolBhav.Domain.AppNotices;
using MolBhav.Domain.Audit;
using MolBhav.Domain.Common.Results;
using MolBhav.Domain.FeatureSwitches;
using MolBhav.Domain.Support;
using MolBhav.UnitTests.Billing;

namespace MolBhav.UnitTests.Admin;

public sealed class AuditLogTests
{
    private static readonly DateTimeOffset Now = new(2026, 11, 1, 6, 0, 0, TimeSpan.Zero);
    private static readonly Guid Admin = Guid.CreateVersion7();

    private readonly IAuditEntryRepository _entries = Substitute.For<IAuditEntryRepository>();
    private readonly ICurrentUser _user = Substitute.For<ICurrentUser>();

    private AuditBehavior<SetFeatureSwitchCommand, Result> Behavior() =>
        new(_entries, _user, new FixedTimeProvider(Now));

    private static readonly SetFeatureSwitchCommand Command = new(AppFeature.Ads, false);

    [Fact]
    public void An_entry_keeps_who_what_which_and_when()
    {
        var entry = AuditEntry.Create(Admin, "Feature.Set", "Ads", "Turned Ads off", Now);

        Assert.Equal(Admin, entry.ActorUserId);
        Assert.Equal("Feature.Set", entry.Action);
        Assert.Equal("Ads", entry.Target);
        Assert.Equal("Turned Ads off", entry.Summary);
        Assert.Equal(Now, entry.OccurredAtUtc);
    }

    [Fact]
    public void Long_or_blank_texts_are_cut_or_dropped_never_refused()
    {
        var entry = AuditEntry.Create(
            Admin, new string('a', 200), "   ", new string('s', 1000), Now);

        Assert.Equal(AuditEntry.ActionMaxLength, entry.Action.Length);
        Assert.Null(entry.Target);
        Assert.Equal(AuditEntry.SummaryMaxLength, entry.Summary.Length);
        Assert.Equal("Unknown", AuditEntry.Create(Admin, null, null, null, Now).Action);
    }

    [Fact]
    public async Task A_successful_admin_command_is_recorded_with_its_actor()
    {
        _user.UserId.Returns(Admin);

        var result = await Behavior().Handle(Command, _ => Task.FromResult(Result.Success()), CancellationToken.None);

        Assert.True(result.IsSuccess);
        _entries.Received(1).Add(Arg.Is<AuditEntry>(e =>
            e.ActorUserId == Admin
            && e.Action == "Feature.Set"
            && e.Target == "Ads"
            && e.Summary == "Turned Ads off"
            && e.OccurredAtUtc == Now));
    }

    [Fact]
    public async Task A_failed_command_is_not_recorded()
    {
        _user.UserId.Returns(Admin);

        var result = await Behavior().Handle(
            Command, _ => Task.FromResult(Result.Failure(Error.Validation("X.Failed", "no"))), CancellationToken.None);

        Assert.True(result.IsFailure);
        _entries.DidNotReceive().Add(Arg.Any<AuditEntry>());
    }

    [Fact]
    public async Task A_command_with_no_signed_in_user_is_a_background_job_and_is_skipped()
    {
        _user.UserId.Returns((Guid?)null);

        await Behavior().Handle(Command, _ => Task.FromResult(Result.Success()), CancellationToken.None);

        _entries.DidNotReceive().Add(Arg.Any<AuditEntry>());
    }

    [Fact]
    public void Each_audited_command_describes_itself_without_personal_data()
    {
        var user = Guid.NewGuid();
        var source = Guid.NewGuid();
        var campaign = Guid.NewGuid();
        IAuditedCommand[] commands =
        [
            new SetUserStatusCommand(user, UserStatusAction.Suspend, Admin),
            new SetUserStatusCommand(user, UserStatusAction.Reinstate, Admin),
            new SetAppNoticeCommand(true, NoticeSeverity.Maintenance, "A private message about someone"),
            new SetAppNoticeCommand(false, NoticeSeverity.Info, null),
            new SetFeatureSwitchCommand(AppFeature.Reports, true),
            new SetAppVersionPolicyCommand("1.2", "https://example.com/update"),
            new SetAppVersionPolicyCommand(null, null),
            new ImportFeedMarketsCommand(source, "Gujarat", ["Rajkot", "Anand"]),
            new SetCampaignStatusCommand(campaign, CampaignStatusAction.Pause),
            new AddAdminTicketMessageCommand(campaign, "Your refund for the double payment is on its way"),
            new UpdateTicketStatusCommand(campaign, SupportTicketStatus.Resolved),
        ];

        foreach (var command in commands)
        {
            Assert.False(string.IsNullOrWhiteSpace(command.AuditAction));
            Assert.Matches(@"^[A-Za-z]+\.[A-Za-z]+$", command.AuditAction);
            Assert.False(string.IsNullOrWhiteSpace(command.AuditSummary));
            // Message text and links are not copied into the log.
            Assert.DoesNotContain("private message", command.AuditSummary);
            Assert.DoesNotContain("example.com", command.AuditSummary);
        }

        Assert.Equal("User.Suspend", commands[0].AuditAction);
        Assert.Equal("User.Reinstate", commands[1].AuditAction);
        Assert.Equal(user.ToString(), commands[0].AuditTarget);
        Assert.Equal("Turned the app message on (Maintenance)", commands[2].AuditSummary);
        Assert.Equal("Turned the app message off", commands[3].AuditSummary);
        Assert.Equal("Reports", commands[4].AuditTarget);
        Assert.Equal("Set the minimum app version to 1.2", commands[5].AuditSummary);
        Assert.Equal("Cleared the minimum app version", commands[6].AuditSummary);
        Assert.Equal("Gujarat", commands[7].AuditTarget);
        Assert.Equal("Paused an ad campaign", commands[8].AuditSummary);
        Assert.Equal("Support.Reply", commands[9].AuditAction);
        // A reply is the user's private conversation; its text never reaches the log.
        Assert.DoesNotContain("refund", commands[9].AuditSummary);
        Assert.Equal("Support.SetStatus", commands[10].AuditAction);
        Assert.Equal("Set a support ticket to Resolved", commands[10].AuditSummary);
    }

    [Fact]
    public void The_behavior_only_wraps_audited_commands()
    {
        // The pipeline constraint keeps ordinary commands and queries out of the audit log.
        Assert.False(typeof(IAuditedCommand).IsAssignableFrom(typeof(MolBhav.Application.Features.Pricing.GetPriceDataStatus.GetPriceDataStatusQuery)));
        Assert.True(typeof(IRequest<Result>).IsAssignableFrom(typeof(SetFeatureSwitchCommand)));
    }
}
