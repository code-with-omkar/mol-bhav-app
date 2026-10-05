using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPriceChangeAlertType : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules");

            migrationBuilder.AddCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules",
                sql: "(threshold_type IN ('PriceDrop', 'PriceSpike', 'PriceChange') AND threshold_percent IS NOT NULL AND threshold_price IS NULL) OR (threshold_type IN ('PriceBelow', 'PriceAbove') AND threshold_price IS NOT NULL AND threshold_percent IS NULL)");

            // Every PriceDrop rule so far came from the app's "Changes by %" option, which the user meant as either way.
            migrationBuilder.Sql("UPDATE alerting.alert_rules SET threshold_type = 'PriceChange' WHERE threshold_type = 'PriceDrop';");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules");

            // The old constraint has no PriceChange; fall back to the previous meaning of "Changes by %".
            migrationBuilder.Sql("UPDATE alerting.alert_rules SET threshold_type = 'PriceDrop' WHERE threshold_type = 'PriceChange';");

            migrationBuilder.AddCheckConstraint(
                name: "ck_alert_rules_threshold",
                schema: "alerting",
                table: "alert_rules",
                sql: "(threshold_type IN ('PriceDrop', 'PriceSpike') AND threshold_percent IS NOT NULL AND threshold_price IS NULL) OR (threshold_type IN ('PriceBelow', 'PriceAbove') AND threshold_price IS NOT NULL AND threshold_percent IS NULL)");
        }
    }
}
