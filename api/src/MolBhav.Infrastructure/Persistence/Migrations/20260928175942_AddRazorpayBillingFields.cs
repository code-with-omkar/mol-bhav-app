using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRazorpayBillingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<long>(
                name: "amount_paise",
                schema: "billing",
                table: "subscriptions",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<string>(
                name: "billing_cycle",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "Monthly");

            migrationBuilder.AddColumn<string>(
                name: "coupon_code",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "currency",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(3)",
                maxLength: 3,
                nullable: false,
                defaultValue: "INR");

            migrationBuilder.AddColumn<long>(
                name: "discount_paise",
                schema: "billing",
                table: "subscriptions",
                type: "bigint",
                nullable: false,
                defaultValue: 0L);

            migrationBuilder.AddColumn<string>(
                name: "razorpay_order_id",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "razorpay_payment_id",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(50)",
                maxLength: 50,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "razorpay_signature",
                schema: "billing",
                table: "subscriptions",
                type: "character varying(512)",
                maxLength: 512,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_subscriptions_razorpay_order_id",
                schema: "billing",
                table: "subscriptions",
                column: "razorpay_order_id",
                unique: true,
                filter: "razorpay_order_id IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "ix_subscriptions_razorpay_payment_id",
                schema: "billing",
                table: "subscriptions",
                column: "razorpay_payment_id",
                unique: true,
                filter: "razorpay_payment_id IS NOT NULL");

            migrationBuilder.AddCheckConstraint(
                name: "ck_subscriptions_amounts",
                schema: "billing",
                table: "subscriptions",
                sql: "amount_paise >= 0 AND discount_paise >= 0 AND discount_paise <= amount_paise");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_subscriptions_razorpay_order_id",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropIndex(
                name: "ix_subscriptions_razorpay_payment_id",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropCheckConstraint(
                name: "ck_subscriptions_amounts",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "amount_paise",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "billing_cycle",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "coupon_code",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "currency",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "discount_paise",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "razorpay_order_id",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "razorpay_payment_id",
                schema: "billing",
                table: "subscriptions");

            migrationBuilder.DropColumn(
                name: "razorpay_signature",
                schema: "billing",
                table: "subscriptions");
        }
    }
}
