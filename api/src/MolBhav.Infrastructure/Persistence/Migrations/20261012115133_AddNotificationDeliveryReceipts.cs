using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddNotificationDeliveryReceipts : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "delivered_at_utc",
                schema: "notification",
                table: "notifications",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "provider_message_id",
                schema: "notification",
                table: "notifications",
                type: "character varying(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "ix_notifications_provider_message_id",
                schema: "notification",
                table: "notifications",
                column: "provider_message_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_notifications_provider_message_id",
                schema: "notification",
                table: "notifications");

            migrationBuilder.DropColumn(
                name: "delivered_at_utc",
                schema: "notification",
                table: "notifications");

            migrationBuilder.DropColumn(
                name: "provider_message_id",
                schema: "notification",
                table: "notifications");
        }
    }
}
