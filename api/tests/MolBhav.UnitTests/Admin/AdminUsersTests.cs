using MolBhav.Application.Abstractions.Admin;
using MolBhav.Application.Abstractions.Identity;
using MolBhav.Application.Common.Models;
using MolBhav.Application.Features.Admin.GetAdminUser;
using MolBhav.Application.Features.Admin.GetAdminUsers;
using MolBhav.Application.Features.Admin.Models;
using MolBhav.Application.Features.Admin.SetUserStatus;
using MolBhav.Domain.Identity;
using MolBhav.Domain.SharedKernel;

namespace MolBhav.UnitTests.Admin;

public sealed class AdminUsersTests
{
    private readonly IUserRepository _users = Substitute.For<IUserRepository>();
    private readonly IAdminUserReadService _readService = Substitute.For<IAdminUserReadService>();
    private readonly Guid _admin = Guid.CreateVersion7();

    private static User NewUser(UserRole role = UserRole.User)
    {
        var user = User.Register(PhoneNumber.Create("9876543210").Value);
        // The role is only ever granted out-of-band (see README), so tests set it the same way: directly.
        typeof(User).GetProperty(nameof(User.Role))!.SetValue(user, role);
        return user;
    }

    private SetUserStatusCommandHandler SetStatusHandler(User? user)
    {
        _users.GetByIdAsync(Arg.Any<Guid>(), Arg.Any<CancellationToken>()).Returns(user);
        return new SetUserStatusCommandHandler(_users);
    }

    [Fact]
    public void A_user_can_be_suspended_and_reinstated()
    {
        var user = NewUser();

        Assert.True(user.Suspend().IsSuccess);
        Assert.Equal(UserStatus.Suspended, user.Status);

        Assert.True(user.Reinstate().IsSuccess);
        Assert.Equal(UserStatus.Active, user.Status);
    }

    [Fact]
    public void Suspending_twice_or_reinstating_an_active_user_is_a_conflict()
    {
        var user = NewUser();

        Assert.Equal("User.NotSuspended", user.Reinstate().Error.Code);

        user.Suspend();
        Assert.Equal("User.AlreadySuspended", user.Suspend().Error.Code);
    }

    [Fact]
    public void An_admin_cannot_be_suspended()
    {
        var admin = NewUser(UserRole.Admin);

        Assert.Equal("User.AdminCannotBeSuspended", admin.Suspend().Error.Code);
        Assert.Equal(UserStatus.Active, admin.Status);
    }

    [Fact]
    public async Task The_handler_suspends_another_user()
    {
        var user = NewUser();

        var result = await SetStatusHandler(user).Handle(new(user.Id, UserStatusAction.Suspend, _admin), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(UserStatus.Suspended, user.Status);
    }

    [Fact]
    public async Task The_handler_reinstates_a_suspended_user()
    {
        var user = NewUser();
        user.Suspend();

        var result = await SetStatusHandler(user).Handle(new(user.Id, UserStatusAction.Reinstate, _admin), CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal(UserStatus.Active, user.Status);
    }

    [Fact]
    public async Task Nobody_can_change_their_own_status()
    {
        var user = NewUser();

        var result = await SetStatusHandler(user).Handle(new(_admin, UserStatusAction.Suspend, _admin), CancellationToken.None);

        Assert.Equal("User.CannotChangeOwnStatus", result.Error.Code);
        await _users.DidNotReceiveWithAnyArgs().GetByIdAsync(default, default);
    }

    [Fact]
    public async Task An_unknown_user_is_not_found()
    {
        var result = await SetStatusHandler(null).Handle(new(Guid.CreateVersion7(), UserStatusAction.Suspend, _admin), CancellationToken.None);

        Assert.Equal("User.NotFound", result.Error.Code);
    }

    [Fact]
    public async Task The_handler_passes_on_the_domain_refusals()
    {
        var admin = NewUser(UserRole.Admin);

        var result = await SetStatusHandler(admin).Handle(new(admin.Id, UserStatusAction.Suspend, _admin), CancellationToken.None);

        Assert.Equal("User.AdminCannotBeSuspended", result.Error.Code);
    }

    [Fact]
    public async Task The_list_passes_trimmed_search_filters_and_paging_through()
    {
        _readService.GetUsersAsync(Arg.Any<AdminUserFilter>(), Arg.Any<CancellationToken>())
            .Returns(new PagedResult<AdminUserResponse>([], 2, 20, 0));

        var result = await new GetAdminUsersQueryHandler(_readService).Handle(
            new("  9876  ", UserStatus.Suspended, SubscriptionTier.Pro, 2, 20), CancellationToken.None);

        Assert.True(result.IsSuccess);
        await _readService.Received(1).GetUsersAsync(
            Arg.Is<AdminUserFilter>(f =>
                f.Search == "9876" && f.Status == UserStatus.Suspended && f.Tier == SubscriptionTier.Pro && f.Page.Page == 2 && f.Page.PageSize == 20),
            Arg.Any<CancellationToken>());
    }

    [Fact]
    public async Task One_user_is_returned_or_not_found()
    {
        var id = Guid.CreateVersion7();
        var detail = new AdminUserDetailResponse(
            new AdminUserResponse(id, "+919876543210", "Asha", UserRole.User, UserStatus.Active, SubscriptionTier.Free, null, null, null, null, DateTimeOffset.UnixEpoch),
            ["agriculture"], null, 2, 1);
        _readService.GetUserAsync(id, Arg.Any<CancellationToken>()).Returns(detail);
        var handler = new GetAdminUserQueryHandler(_readService);

        Assert.Equal(detail, (await handler.Handle(new(id), CancellationToken.None)).Value);
        Assert.Equal("User.NotFound", (await handler.Handle(new(Guid.CreateVersion7()), CancellationToken.None)).Error.Code);
    }

    [Theory]
    [InlineData("", true)]
    [InlineData("9876", true)]
    public void The_search_text_has_a_length_limit(string search, bool valid)
    {
        var validator = new GetAdminUsersQueryValidator();

        Assert.Equal(valid, validator.Validate(new GetAdminUsersQuery(search, null, null, 1, 20)).IsValid);
        Assert.False(validator.Validate(new GetAdminUsersQuery(new string('x', GetAdminUsersQueryValidator.SearchMaxLength + 1), null, null, 1, 20)).IsValid);
    }
}
