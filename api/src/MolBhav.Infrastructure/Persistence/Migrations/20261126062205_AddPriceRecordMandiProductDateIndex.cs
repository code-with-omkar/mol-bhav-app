using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPriceRecordMandiProductDateIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "ix_price_records_mandi_id_product_id_record_date",
                schema: "pricing",
                table: "price_records",
                columns: new[] { "mandi_id", "product_id", "record_date" },
                descending: new[] { false, false, true },
                filter: "mandi_id IS NOT NULL AND NOT is_voided");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "ix_price_records_mandi_id_product_id_record_date",
                schema: "pricing",
                table: "price_records");
        }
    }
}
