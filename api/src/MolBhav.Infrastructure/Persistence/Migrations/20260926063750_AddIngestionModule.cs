using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddIngestionModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "ingestion");

            migrationBuilder.CreateTable(
                name: "ingestion_jobs",
                schema: "ingestion",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    price_source_id = table.Column<Guid>(type: "uuid", nullable: false),
                    trigger_type = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    triggered_by_user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    status = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    records_fetched = table.Column<int>(type: "integer", nullable: false),
                    records_persisted = table.Column<int>(type: "integer", nullable: false),
                    records_failed = table.Column<int>(type: "integer", nullable: false),
                    failure_reason = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    started_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    completed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ingestion_jobs", x => x.id);
                    table.ForeignKey(
                        name: "fk_ingestion_jobs_price_sources_price_source_id",
                        column: x => x.price_source_id,
                        principalSchema: "pricing",
                        principalTable: "price_sources",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "fk_ingestion_jobs_users_triggered_by_user_id",
                        column: x => x.triggered_by_user_id,
                        principalSchema: "identity",
                        principalTable: "users",
                        principalColumn: "id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "ingestion_errors",
                schema: "ingestion",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    job_id = table.Column<Guid>(type: "uuid", nullable: false),
                    raw_payload = table.Column<string>(type: "jsonb", nullable: false),
                    error_message = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    occurred_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ingestion_errors", x => x.id);
                    table.ForeignKey(
                        name: "fk_ingestion_errors_ingestion_jobs_job_id",
                        column: x => x.job_id,
                        principalSchema: "ingestion",
                        principalTable: "ingestion_jobs",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_errors_job_id_occurred_at_utc",
                schema: "ingestion",
                table: "ingestion_errors",
                columns: new[] { "job_id", "occurred_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_jobs_price_source_id_started_at_utc",
                schema: "ingestion",
                table: "ingestion_jobs",
                columns: new[] { "price_source_id", "started_at_utc" });

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_jobs_status",
                schema: "ingestion",
                table: "ingestion_jobs",
                column: "status");

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_jobs_triggered_by_user_id",
                schema: "ingestion",
                table: "ingestion_jobs",
                column: "triggered_by_user_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ingestion_errors",
                schema: "ingestion");

            migrationBuilder.DropTable(
                name: "ingestion_jobs",
                schema: "ingestion");
        }
    }
}
