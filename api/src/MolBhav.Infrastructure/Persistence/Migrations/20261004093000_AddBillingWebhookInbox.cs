using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBillingWebhookInbox : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "webhook_inbox",
                schema: "billing",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    provider = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    event_id = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    event_type = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    payload = table.Column<string>(type: "jsonb", nullable: false),
                    received_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    next_attempt_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    attempt_count = table.Column<int>(type: "integer", nullable: false),
                    last_attempt_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    last_error = table.Column<string>(type: "character varying(2000)", maxLength: 2000, nullable: true),
                    processed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    parked_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_webhook_inbox", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "ix_webhook_inbox_next_attempt_at_utc",
                schema: "billing",
                table: "webhook_inbox",
                column: "next_attempt_at_utc",
                filter: "processed_at_utc IS NULL AND parked_at_utc IS NULL");

            migrationBuilder.CreateIndex(
                name: "ix_webhook_inbox_parked_at_utc",
                schema: "billing",
                table: "webhook_inbox",
                column: "parked_at_utc",
                filter: "parked_at_utc IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "ix_webhook_inbox_provider_event_id",
                schema: "billing",
                table: "webhook_inbox",
                columns: new[] { "provider", "event_id" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "webhook_inbox",
                schema: "billing");
        }
    }
}
