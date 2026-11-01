using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSourceFeedOptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "source_feed_options",
                schema: "ingestion",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    price_source_id = table.Column<Guid>(type: "uuid", nullable: false),
                    commodities = table.Column<string>(type: "jsonb", nullable: false),
                    markets = table.Column<string>(type: "jsonb", nullable: false),
                    refreshed_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_source_feed_options", x => x.id);
                    table.ForeignKey(
                        name: "fk_source_feed_options_price_sources_price_source_id",
                        column: x => x.price_source_id,
                        principalSchema: "pricing",
                        principalTable: "price_sources",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "ix_source_feed_options_price_source_id",
                schema: "ingestion",
                table: "source_feed_options",
                column: "price_source_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "source_feed_options",
                schema: "ingestion");
        }
    }
}
