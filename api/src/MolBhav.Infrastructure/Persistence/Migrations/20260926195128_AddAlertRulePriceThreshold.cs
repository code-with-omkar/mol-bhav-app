using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAlertRulePriceThreshold : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<decimal>(
                name: "threshold_percent",
                schema: "alerting",
                table: "alert_rules",
                type: "numeric(5,2)",
                precision: 5,
                scale: 2,
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric(5,2)",
                oldPrecision: 5,
                oldScale: 2);

            migrationBuilder.AddColumn<decimal>(
                name: "threshold_price",
                schema: "alerting",
                table: "alert_rules",
                type: "numeric(14,2)",
                precision: 14,
                scale: 2,
                nullable: true);

            migrationBuilder.AddCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules",
                sql: "(threshold_type IN ('PriceDrop', 'PriceSpike') AND threshold_percent IS NOT NULL AND threshold_price IS NULL) OR (threshold_type IN ('PriceBelow', 'PriceAbove') AND threshold_price IS NOT NULL AND threshold_percent IS NULL)");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules");

            migrationBuilder.DropColumn(
                name: "threshold_price",
                schema: "alerting",
                table: "alert_rules");

            migrationBuilder.AlterColumn<decimal>(
                name: "threshold_percent",
                schema: "alerting",
                table: "alert_rules",
                type: "numeric(5,2)",
                precision: 5,
                scale: 2,
                nullable: false,
                defaultValue: 0m,
                oldClrType: typeof(decimal),
                oldType: "numeric(5,2)",
                oldPrecision: 5,
                oldScale: 2,
                oldNullable: true);
        }
    }
}
