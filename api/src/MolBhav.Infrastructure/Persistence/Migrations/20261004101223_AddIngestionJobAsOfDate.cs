using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddIngestionJobAsOfDate : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateOnly>(
                name: "as_of_date",
                schema: "ingestion",
                table: "ingestion_jobs",
                type: "date",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "records_unchanged",
                schema: "ingestion",
                table: "ingestion_jobs",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "as_of_date",
                schema: "ingestion",
                table: "ingestion_jobs");

            migrationBuilder.DropColumn(
                name: "records_unchanged",
                schema: "ingestion",
                table: "ingestion_jobs");
        }
    }
}
