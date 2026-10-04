using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddIngestionSchedules : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ingestion_schedules",
                schema: "ingestion",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    price_source_id = table.Column<Guid>(type: "uuid", nullable: false),
                    is_enabled = table.Column<bool>(type: "boolean", nullable: false),
                    frequency = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    time_of_day = table.Column<TimeOnly>(type: "time without time zone", nullable: false),
                    day_of_week = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: true),
                    interval_hours = table.Column<int>(type: "integer", nullable: true),
                    next_run_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    last_run_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_ingestion_schedules", x => x.id);
                    table.CheckConstraint("ck_ingestion_schedules_day_of_week", "(frequency = 'Weekly' AND day_of_week IS NOT NULL) OR (frequency <> 'Weekly' AND day_of_week IS NULL)");
                    table.CheckConstraint("ck_ingestion_schedules_interval_hours", "(frequency = 'EveryNHours' AND interval_hours IN (1, 2, 3, 4, 6, 8, 12)) OR (frequency <> 'EveryNHours' AND interval_hours IS NULL)");
                    table.CheckConstraint("ck_ingestion_schedules_next_run", "(is_enabled AND next_run_at_utc IS NOT NULL) OR (NOT is_enabled AND next_run_at_utc IS NULL)");
                    table.ForeignKey(
                        name: "fk_ingestion_schedules_price_sources_price_source_id",
                        column: x => x.price_source_id,
                        principalSchema: "pricing",
                        principalTable: "price_sources",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_schedules_next_run_at_utc",
                schema: "ingestion",
                table: "ingestion_schedules",
                column: "next_run_at_utc",
                filter: "is_enabled");

            migrationBuilder.CreateIndex(
                name: "ix_ingestion_schedules_price_source_id",
                schema: "ingestion",
                table: "ingestion_schedules",
                column: "price_source_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ingestion_schedules",
                schema: "ingestion");
        }
    }
}
