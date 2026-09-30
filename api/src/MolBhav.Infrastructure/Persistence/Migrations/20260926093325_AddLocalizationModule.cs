using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddLocalizationModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.EnsureSchema(
                name: "localization");

            migrationBuilder.CreateTable(
                name: "localized_text_entries",
                schema: "localization",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false),
                    key = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    description = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: true),
                    created_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_by = table.Column<Guid>(type: "uuid", nullable: true),
                    updated_at_utc = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_by = table.Column<Guid>(type: "uuid", nullable: true),
                    xmin = table.Column<uint>(type: "xid", rowVersion: true, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_localized_text_entries", x => x.id);
                    table.UniqueConstraint("ak_localized_text_entries_key", x => x.key);
                });

            migrationBuilder.CreateTable(
                name: "localized_text_values",
                schema: "localization",
                columns: table => new
                {
                    language_code = table.Column<string>(type: "character(2)", fixedLength: true, maxLength: 2, nullable: false),
                    text_entry_id = table.Column<Guid>(type: "uuid", nullable: false),
                    text = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("pk_localized_text_values", x => new { x.text_entry_id, x.language_code });
                    table.ForeignKey(
                        name: "fk_localized_text_values_owner",
                        column: x => x.text_entry_id,
                        principalSchema: "localization",
                        principalTable: "localized_text_entries",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "localized_text_values",
                schema: "localization");

            migrationBuilder.DropTable(
                name: "localized_text_entries",
                schema: "localization");
        }
    }
}
