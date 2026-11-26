using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Takes the Construction category out until it is built properly: its sub-categories, products, variants, prices,
    /// price source, sample suppliers and anything users saved against them. The tables and code stay, so a later
    /// migration can add the data again. Down does not restore the rows.
    /// </summary>
    public partial class RemoveConstructionData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                CREATE TEMP TABLE gone_products ON COMMIT DROP AS
                    SELECT p.id FROM catalog.products p
                    JOIN catalog.sub_categories s ON s.id = p.sub_category_id
                    JOIN catalog.procurement_categories c ON c.id = s.category_id
                    WHERE c.code = 'construction';
                CREATE TEMP TABLE gone_sources ON COMMIT DROP AS
                    SELECT ps.id FROM pricing.price_sources ps
                    JOIN catalog.procurement_categories c ON c.id = ps.category_id
                    WHERE c.code = 'construction';
                CREATE TEMP TABLE gone_suppliers ON COMMIT DROP AS
                    SELECT id FROM market.suppliers
                    WHERE code IN ('mumbai-build-supply', 'nashik-steel-mart', 'pune-cement-depot', 'pune-steel-traders', 'satara-sand-co');

                DELETE FROM alerting.alerts
                    WHERE product_id IN (SELECT id FROM gone_products) OR supplier_id IN (SELECT id FROM gone_suppliers);
                DELETE FROM alerting.alert_rules
                    WHERE product_id IN (SELECT id FROM gone_products) OR supplier_id IN (SELECT id FROM gone_suppliers);
                DELETE FROM alerting.market_opportunities
                    WHERE product_id IN (SELECT id FROM gone_products)
                       OR home_supplier_id IN (SELECT id FROM gone_suppliers)
                       OR best_supplier_id IN (SELECT id FROM gone_suppliers);
                DELETE FROM procurement.procurement_opportunities
                    WHERE requirement_id IN (SELECT id FROM procurement.procurement_requirements WHERE product_id IN (SELECT id FROM gone_products));
                DELETE FROM procurement.procurement_requirements WHERE product_id IN (SELECT id FROM gone_products);
                DELETE FROM watchlist.watchlist_items WHERE product_id IN (SELECT id FROM gone_products);
                DELETE FROM pricing.price_records
                    WHERE product_id IN (SELECT id FROM gone_products)
                       OR price_source_id IN (SELECT id FROM gone_sources)
                       OR supplier_id IN (SELECT id FROM gone_suppliers);

                DELETE FROM ingestion.ingestion_errors
                    WHERE job_id IN (SELECT id FROM ingestion.ingestion_jobs WHERE price_source_id IN (SELECT id FROM gone_sources));
                DELETE FROM ingestion.ingestion_jobs WHERE price_source_id IN (SELECT id FROM gone_sources);
                DELETE FROM ingestion.ingestion_schedules WHERE price_source_id IN (SELECT id FROM gone_sources);
                DELETE FROM ingestion.source_feed_options WHERE price_source_id IN (SELECT id FROM gone_sources);
                DELETE FROM pricing.price_sources WHERE id IN (SELECT id FROM gone_sources);
                DELETE FROM market.suppliers WHERE id IN (SELECT id FROM gone_suppliers);

                DELETE FROM catalog.product_variants WHERE product_id IN (SELECT id FROM gone_products);
                DELETE FROM catalog.products WHERE id IN (SELECT id FROM gone_products);
                DELETE FROM identity.user_categories WHERE category_code = 'construction';
                DELETE FROM promotions.campaign_targets WHERE category_code = 'construction';
                DELETE FROM catalog.sub_categories
                    WHERE category_id IN (SELECT id FROM catalog.procurement_categories WHERE code = 'construction');
                DELETE FROM catalog.procurement_categories WHERE code = 'construction';
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
        }
    }
}
