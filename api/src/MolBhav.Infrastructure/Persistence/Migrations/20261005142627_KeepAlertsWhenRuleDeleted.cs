using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class KeepAlertsWhenRuleDeleted : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_alerts_alert_rules_alert_rule_id",
                schema: "alerting",
                table: "alerts");

            migrationBuilder.AlterColumn<Guid>(
                name: "alert_rule_id",
                schema: "alerting",
                table: "alerts",
                type: "uuid",
                nullable: true,
                oldClrType: typeof(Guid),
                oldType: "uuid");

            migrationBuilder.AddForeignKey(
                name: "fk_alerts_alert_rules_alert_rule_id",
                schema: "alerting",
                table: "alerts",
                column: "alert_rule_id",
                principalSchema: "alerting",
                principalTable: "alert_rules",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "fk_alerts_alert_rules_alert_rule_id",
                schema: "alerting",
                table: "alerts");

            migrationBuilder.AlterColumn<Guid>(
                name: "alert_rule_id",
                schema: "alerting",
                table: "alerts",
                type: "uuid",
                nullable: false,
                defaultValue: new Guid("00000000-0000-0000-0000-000000000000"),
                oldClrType: typeof(Guid),
                oldType: "uuid",
                oldNullable: true);

            migrationBuilder.AddForeignKey(
                name: "fk_alerts_alert_rules_alert_rule_id",
                schema: "alerting",
                table: "alerts",
                column: "alert_rule_id",
                principalSchema: "alerting",
                principalTable: "alert_rules",
                principalColumn: "id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
