using MolBhav.Domain.Identity;
using static MolBhav.UnitTests.Identity.PasswordLoginTestContext;

namespace MolBhav.UnitTests.Identity;

public sealed class UserPasswordTests
{
    [Fact]
    public void RecordFailedPasswordAttempt_BelowLimit_DoesNotLock()
    {
        var user = User.RegisterWithPassword(PhoneNumber, "hash:x");

        for (var i = 1; i < User.MaxFailedPasswordAttempts; i++)
        {
            user.RecordFailedPasswordAttempt(Now);
        }

        Assert.False(user.IsPasswordLockedOut(Now));
        Assert.Equal(User.MaxFailedPasswordAttempts - 1, user.FailedPasswordAttempts);
    }

    [Fact]
    public void RecordFailedPasswordAttempt_AtLimit_LocksForTheLockoutDurationAndResetsCount()
    {
        var user = User.RegisterWithPassword(PhoneNumber, "hash:x");

        for (var i = 0; i < User.MaxFailedPasswordAttempts; i++)
        {
            user.RecordFailedPasswordAttempt(Now);
        }

        Assert.True(user.IsPasswordLockedOut(Now));
        Assert.False(user.IsPasswordLockedOut(Now.Add(User.PasswordLockoutDuration)));
        Assert.Equal(0, user.FailedPasswordAttempts);
    }

    [Fact]
    public void RecordLogin_ClearsCountersAndLockout()
    {
        var user = User.RegisterWithPassword(PhoneNumber, "hash:x");
        for (var i = 0; i < User.MaxFailedPasswordAttempts + 2; i++)
        {
            user.RecordFailedPasswordAttempt(Now);
        }

        user.RecordLogin(Now);

        Assert.False(user.IsPasswordLockedOut(Now));
        Assert.Equal(0, user.FailedPasswordAttempts);
    }
}
