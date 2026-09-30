using MolBhav.Domain.Billing;
using static MolBhav.UnitTests.Billing.BillingTestData;

namespace MolBhav.UnitTests.Billing;

public sealed class CouponTests
{
    [Fact]
    public void Create_StoresCodeUppercase()
    {
        var coupon = BillingTestData.Coupon();

        Assert.Equal("LAUNCH50", coupon.Code);
    }

    [Fact]
    public void CalculateDiscount_Percent_TakesThatShareOfTheAmount()
    {
        var coupon = BillingTestData.Coupon(DiscountType.Percent, 10);

        Assert.Equal(4_990, coupon.CalculateDiscount(49_900));
    }

    [Fact]
    public void CalculateDiscount_Fixed_TakesTheFixedAmount()
    {
        var coupon = BillingTestData.Coupon(DiscountType.Fixed, 10_000);

        Assert.Equal(10_000, coupon.CalculateDiscount(49_900));
    }

    [Fact]
    public void CalculateDiscount_FixedAboveAmount_IsCappedToKeepTheMinimumCharge()
    {
        var coupon = BillingTestData.Coupon(DiscountType.Fixed, 100_000);

        Assert.Equal(49_900 - Domain.Billing.Coupon.MinimumChargePaise, coupon.CalculateDiscount(49_900));
    }

    [Fact]
    public void CalculateDiscount_HundredPercent_LeavesTheHundredPaiseFloor()
    {
        var coupon = BillingTestData.Coupon(DiscountType.Percent, 100);

        Assert.Equal(49_800, coupon.CalculateDiscount(49_900));
    }

    [Fact]
    public void CalculateDiscount_AmountAtOrBelowFloor_GivesNothing()
    {
        var coupon = BillingTestData.Coupon(DiscountType.Percent, 50);

        Assert.Equal(0, coupon.CalculateDiscount(100));
    }

    [Fact]
    public void IsRedeemableFor_ValidCoupon_IsTrue()
    {
        var coupon = BillingTestData.Coupon();

        Assert.True(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_Expired_IsFalse()
    {
        var coupon = BillingTestData.Coupon(validFrom: Now.AddDays(-10), validTo: Now.AddDays(-1));

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_NotYetValid_IsFalse()
    {
        var coupon = BillingTestData.Coupon(validFrom: Now.AddDays(1));

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_OtherPlan_IsFalse()
    {
        var coupon = BillingTestData.Coupon(planCode: "pro-yearly");

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_BelowMinimumAmount_IsFalse()
    {
        var coupon = BillingTestData.Coupon(minAmountPaise: 100_000);

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_MaxUsesReached_IsFalse()
    {
        var coupon = BillingTestData.Coupon(maxUses: 3).WithUses(3);

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void IsRedeemableFor_Deactivated_IsFalse()
    {
        var coupon = BillingTestData.Coupon();
        coupon.Update(isActive: false, validTo: null, maxUses: null);

        Assert.False(coupon.IsRedeemableFor("pro-monthly", 49_900, Now));
    }

    [Fact]
    public void Create_PercentAbove100_Fails()
    {
        var result = Domain.Billing.Coupon.Create("BIG", DiscountType.Percent, 101, null, Now, null, null, 0);

        Assert.True(result.IsFailure);
    }

    [Fact]
    public void Update_MaxUsesBelowUsage_Fails()
    {
        var coupon = BillingTestData.Coupon(maxUses: 10).WithUses(5);

        var result = coupon.Update(isActive: true, validTo: null, maxUses: 4);

        Assert.Equal(BillingErrors.CouponMaxUsesBelowUsage, result.Error);
    }
}
