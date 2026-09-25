using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Initial catalog reference data (BRD §11/§12): units, the Agriculture and Construction categories with their
    /// sub-categories, core products and variants — names in English, Hindi and Marathi (other enabled languages fall
    /// back to English until translated in the admin portal). Ids are deterministic (UUIDv5 of each code), so every
    /// environment gets identical ids. Translation rows cascade with their owners on Down.
    /// </summary>
    public partial class SeedCatalogReferenceData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO catalog.units_of_measure (id, code, symbol, dimension, to_base_factor, is_active, created_at_utc, created_by) VALUES
                    ('804d9cd5-8fa0-5580-ae2e-035bc10bacda', 'kg', 'kg', 'Mass', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('9826c24b-8f2c-50e9-8389-9fd99d225462', 'g', 'g', 'Mass', 0.001, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('b36af3ca-6c5b-5593-a0f6-743f5e785936', 'quintal', 'q', 'Mass', 100, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('55dd0941-d052-573a-9fda-309164c490c1', 'tonne', 't', 'Mass', 1000, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 'bag-50kg', 'bag', 'Mass', 50, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('498d2e87-8f57-5220-bc00-226f7fed8d3e', 'piece', 'pc', 'Count', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('135e2afb-812a-5832-8c07-95051ea7437b', 'dozen', 'dz', 'Count', 12, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('7ed82cbf-53b6-5c73-8758-28c17c65a5de', 'litre', 'L', 'Volume', 0.001, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('a531b082-21e7-5a76-880b-054b3feeb534', 'cft', 'cft', 'Volume', 0.028317, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('765d1f58-15c4-58cd-ae34-5c1780540f84', 'brass', 'brass', 'Volume', 2.831685, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('273a73bf-552c-5783-a0a2-31780fe01cd1', 'cum', 'm³', 'Volume', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('ba2ac478-114b-5c1a-bea9-4836d0219185', 'metre', 'm', 'Length', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('57633ab6-89fe-570f-9d05-77453a8bd31f', 'sqft', 'sq ft', 'Area', 0.092903, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.unit_of_measure_translations (unit_id, language_code, name, description) VALUES
                    ('804d9cd5-8fa0-5580-ae2e-035bc10bacda', 'en', 'Kilogram', NULL),
                    ('804d9cd5-8fa0-5580-ae2e-035bc10bacda', 'hi', 'किलोग्राम', NULL),
                    ('804d9cd5-8fa0-5580-ae2e-035bc10bacda', 'mr', 'किलोग्रॅम', NULL),
                    ('9826c24b-8f2c-50e9-8389-9fd99d225462', 'en', 'Gram', NULL),
                    ('9826c24b-8f2c-50e9-8389-9fd99d225462', 'hi', 'ग्राम', NULL),
                    ('9826c24b-8f2c-50e9-8389-9fd99d225462', 'mr', 'ग्रॅम', NULL),
                    ('b36af3ca-6c5b-5593-a0f6-743f5e785936', 'en', 'Quintal', NULL),
                    ('b36af3ca-6c5b-5593-a0f6-743f5e785936', 'hi', 'क्विंटल', NULL),
                    ('b36af3ca-6c5b-5593-a0f6-743f5e785936', 'mr', 'क्विंटल', NULL),
                    ('55dd0941-d052-573a-9fda-309164c490c1', 'en', 'Tonne', NULL),
                    ('55dd0941-d052-573a-9fda-309164c490c1', 'hi', 'टन', NULL),
                    ('55dd0941-d052-573a-9fda-309164c490c1', 'mr', 'टन', NULL),
                    ('91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 'en', 'Bag (50 kg)', NULL),
                    ('91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 'hi', 'बोरी (50 किग्रा)', NULL),
                    ('91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 'mr', 'गोणी (50 किलो)', NULL),
                    ('498d2e87-8f57-5220-bc00-226f7fed8d3e', 'en', 'Piece', NULL),
                    ('498d2e87-8f57-5220-bc00-226f7fed8d3e', 'hi', 'नग', NULL),
                    ('498d2e87-8f57-5220-bc00-226f7fed8d3e', 'mr', 'नग', NULL),
                    ('135e2afb-812a-5832-8c07-95051ea7437b', 'en', 'Dozen', NULL),
                    ('135e2afb-812a-5832-8c07-95051ea7437b', 'hi', 'दर्जन', NULL),
                    ('135e2afb-812a-5832-8c07-95051ea7437b', 'mr', 'डझन', NULL),
                    ('7ed82cbf-53b6-5c73-8758-28c17c65a5de', 'en', 'Litre', NULL),
                    ('7ed82cbf-53b6-5c73-8758-28c17c65a5de', 'hi', 'लीटर', NULL),
                    ('7ed82cbf-53b6-5c73-8758-28c17c65a5de', 'mr', 'लिटर', NULL),
                    ('a531b082-21e7-5a76-880b-054b3feeb534', 'en', 'Cubic foot', NULL),
                    ('a531b082-21e7-5a76-880b-054b3feeb534', 'hi', 'घन फुट', NULL),
                    ('a531b082-21e7-5a76-880b-054b3feeb534', 'mr', 'घनफूट', NULL),
                    ('765d1f58-15c4-58cd-ae34-5c1780540f84', 'en', 'Brass (100 cft)', NULL),
                    ('765d1f58-15c4-58cd-ae34-5c1780540f84', 'hi', 'ब्रास (100 घन फुट)', NULL),
                    ('765d1f58-15c4-58cd-ae34-5c1780540f84', 'mr', 'ब्रास (100 घनफूट)', NULL),
                    ('273a73bf-552c-5783-a0a2-31780fe01cd1', 'en', 'Cubic metre', NULL),
                    ('273a73bf-552c-5783-a0a2-31780fe01cd1', 'hi', 'घन मीटर', NULL),
                    ('273a73bf-552c-5783-a0a2-31780fe01cd1', 'mr', 'घनमीटर', NULL),
                    ('ba2ac478-114b-5c1a-bea9-4836d0219185', 'en', 'Metre', NULL),
                    ('ba2ac478-114b-5c1a-bea9-4836d0219185', 'hi', 'मीटर', NULL),
                    ('ba2ac478-114b-5c1a-bea9-4836d0219185', 'mr', 'मीटर', NULL),
                    ('57633ab6-89fe-570f-9d05-77453a8bd31f', 'en', 'Square foot', NULL),
                    ('57633ab6-89fe-570f-9d05-77453a8bd31f', 'hi', 'वर्ग फुट', NULL),
                    ('57633ab6-89fe-570f-9d05-77453a8bd31f', 'mr', 'चौरस फूट', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.procurement_categories (id, code, icon_key, display_order, is_active, created_at_utc, created_by) VALUES
                    ('f161ea3c-9973-5304-84c3-82e0d2ce655b', 'agriculture', 'agriculture', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('245fba83-5854-55b6-a895-87c08b03b820', 'construction', 'construction', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.procurement_category_translations (category_id, language_code, name, description) VALUES
                    ('f161ea3c-9973-5304-84c3-82e0d2ce655b', 'en', 'Agriculture', 'Vegetables, grains and pulses from APMC mandis'),
                    ('f161ea3c-9973-5304-84c3-82e0d2ce655b', 'hi', 'कृषि', 'एपीएमसी मंडियों से सब्ज़ियाँ, अनाज और दालें'),
                    ('f161ea3c-9973-5304-84c3-82e0d2ce655b', 'mr', 'शेती', 'एपीएमसी बाजार समित्यांतील भाजीपाला, धान्य आणि कडधान्ये'),
                    ('245fba83-5854-55b6-a895-87c08b03b820', 'en', 'Construction', 'Steel, cement, bricks, sand and aggregates'),
                    ('245fba83-5854-55b6-a895-87c08b03b820', 'hi', 'निर्माण', 'स्टील, सीमेंट, ईंट, रेत और गिट्टी'),
                    ('245fba83-5854-55b6-a895-87c08b03b820', 'mr', 'बांधकाम', 'स्टील, सिमेंट, विटा, वाळू आणि खडी');
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.sub_categories (id, category_id, code, display_order, is_active, created_at_utc, created_by) VALUES
                    ('0404b99e-b5c6-5b22-9500-ff23e57bd843', 'f161ea3c-9973-5304-84c3-82e0d2ce655b', 'vegetables', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('661288ad-c9eb-5859-90dc-d844b957f39c', 'f161ea3c-9973-5304-84c3-82e0d2ce655b', 'grains', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('974aa1da-6416-5515-b639-be0e5ef74f94', 'f161ea3c-9973-5304-84c3-82e0d2ce655b', 'pulses', 3, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('e38b0567-3362-527b-bee2-a02507b5ab6d', '245fba83-5854-55b6-a895-87c08b03b820', 'steel', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('b6db3c71-de05-5a88-9f25-ffe548e3572d', '245fba83-5854-55b6-a895-87c08b03b820', 'cement', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('d3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', '245fba83-5854-55b6-a895-87c08b03b820', 'bricks-blocks', 3, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('c58242c0-e045-5485-8ade-1e7dc41b87f3', '245fba83-5854-55b6-a895-87c08b03b820', 'sand-aggregates', 4, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.sub_category_translations (sub_category_id, language_code, name, description) VALUES
                    ('0404b99e-b5c6-5b22-9500-ff23e57bd843', 'en', 'Vegetables', NULL),
                    ('0404b99e-b5c6-5b22-9500-ff23e57bd843', 'hi', 'सब्ज़ियाँ', NULL),
                    ('0404b99e-b5c6-5b22-9500-ff23e57bd843', 'mr', 'भाजीपाला', NULL),
                    ('661288ad-c9eb-5859-90dc-d844b957f39c', 'en', 'Grains', NULL),
                    ('661288ad-c9eb-5859-90dc-d844b957f39c', 'hi', 'अनाज', NULL),
                    ('661288ad-c9eb-5859-90dc-d844b957f39c', 'mr', 'धान्य', NULL),
                    ('974aa1da-6416-5515-b639-be0e5ef74f94', 'en', 'Pulses', NULL),
                    ('974aa1da-6416-5515-b639-be0e5ef74f94', 'hi', 'दालें', NULL),
                    ('974aa1da-6416-5515-b639-be0e5ef74f94', 'mr', 'कडधान्ये', NULL),
                    ('e38b0567-3362-527b-bee2-a02507b5ab6d', 'en', 'Steel', NULL),
                    ('e38b0567-3362-527b-bee2-a02507b5ab6d', 'hi', 'स्टील', NULL),
                    ('e38b0567-3362-527b-bee2-a02507b5ab6d', 'mr', 'स्टील', NULL),
                    ('b6db3c71-de05-5a88-9f25-ffe548e3572d', 'en', 'Cement', NULL),
                    ('b6db3c71-de05-5a88-9f25-ffe548e3572d', 'hi', 'सीमेंट', NULL),
                    ('b6db3c71-de05-5a88-9f25-ffe548e3572d', 'mr', 'सिमेंट', NULL),
                    ('d3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', 'en', 'Bricks & Blocks', NULL),
                    ('d3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', 'hi', 'ईंट और ब्लॉक', NULL),
                    ('d3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', 'mr', 'विटा आणि ब्लॉक', NULL),
                    ('c58242c0-e045-5485-8ade-1e7dc41b87f3', 'en', 'Sand & Aggregates', NULL),
                    ('c58242c0-e045-5485-8ade-1e7dc41b87f3', 'hi', 'रेत और गिट्टी', NULL),
                    ('c58242c0-e045-5485-8ade-1e7dc41b87f3', 'mr', 'वाळू आणि खडी', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.products (id, code, sub_category_id, default_unit_id, display_order, image_key, is_active, created_at_utc, created_by) VALUES
                    ('a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'onion', '0404b99e-b5c6-5b22-9500-ff23e57bd843', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('efe66fb0-01ae-5b35-bb25-40c947777543', 'potato', '0404b99e-b5c6-5b22-9500-ff23e57bd843', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('57012511-ab03-538c-a998-e4a1e60ce840', 'tomato', '0404b99e-b5c6-5b22-9500-ff23e57bd843', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 3, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('03f33965-9259-50a2-abe2-5d1a21a7ee90', 'green-chilli', '0404b99e-b5c6-5b22-9500-ff23e57bd843', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 4, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('55b5b6c9-5dc0-5b48-b921-167215e49bea', 'wheat', '661288ad-c9eb-5859-90dc-d844b957f39c', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('12c60da9-7593-5956-9739-bb71f0c03459', 'rice', '661288ad-c9eb-5859-90dc-d844b957f39c', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('30fda377-fb14-5c9f-ac6d-a80e1b7aaf92', 'jowar', '661288ad-c9eb-5859-90dc-d844b957f39c', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 3, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('abe56060-b038-5d97-948c-eb2914a0e695', 'bajra', '661288ad-c9eb-5859-90dc-d844b957f39c', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 4, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('dc1fc82d-ce54-5c06-828a-c0f7e03fefa3', 'tur', '974aa1da-6416-5515-b639-be0e5ef74f94', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('29e4fc7b-0ea7-5fa4-8c8c-7a6c6faeeb38', 'chana', '974aa1da-6416-5515-b639-be0e5ef74f94', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('7955b143-95e3-540e-b208-b4939878a972', 'moong', '974aa1da-6416-5515-b639-be0e5ef74f94', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 3, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('2f7e8181-4662-5e1f-ae43-cb8bf19fe28d', 'urad', '974aa1da-6416-5515-b639-be0e5ef74f94', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', 4, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('a60ecee4-708c-534e-bd54-7e611da7f553', 'tmt-steel', 'e38b0567-3362-527b-bee2-a02507b5ab6d', '55dd0941-d052-573a-9fda-309164c490c1', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('b335f434-90d2-5626-adc5-442eb3c7875d', 'cement-opc-53', 'b6db3c71-de05-5a88-9f25-ffe548e3572d', '91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('cf16678f-f948-5e08-9139-315a91cdf645', 'cement-ppc', 'b6db3c71-de05-5a88-9f25-ffe548e3572d', '91fe4f3d-2f39-505f-945e-8a8ff1b231a5', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('e3632ccd-6d00-516a-8fd1-7328e93dd84c', 'red-brick', 'd3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', '498d2e87-8f57-5220-bc00-226f7fed8d3e', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('908beb78-128c-5318-afad-de387402e24e', 'aac-block', 'd3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', '498d2e87-8f57-5220-bc00-226f7fed8d3e', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('d54c248f-bfc2-57f8-84d1-c7c11fc84cc1', 'river-sand', 'c58242c0-e045-5485-8ade-1e7dc41b87f3', '765d1f58-15c4-58cd-ae34-5c1780540f84', 1, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('d78e5fbd-734f-5ca3-a597-d491dbbe2bf7', 'm-sand', 'c58242c0-e045-5485-8ade-1e7dc41b87f3', '765d1f58-15c4-58cd-ae34-5c1780540f84', 2, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('c3d5fdba-a85c-59aa-b620-f89be9d39919', 'aggregate-20mm', 'c58242c0-e045-5485-8ade-1e7dc41b87f3', '765d1f58-15c4-58cd-ae34-5c1780540f84', 3, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('807bca64-9217-5fb9-8952-302db242fee8', 'aggregate-10mm', 'c58242c0-e045-5485-8ade-1e7dc41b87f3', '765d1f58-15c4-58cd-ae34-5c1780540f84', 4, NULL, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.product_translations (product_id, language_code, name, description) VALUES
                    ('a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'en', 'Onion', NULL),
                    ('a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'hi', 'प्याज', NULL),
                    ('a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'mr', 'कांदा', NULL),
                    ('efe66fb0-01ae-5b35-bb25-40c947777543', 'en', 'Potato', NULL),
                    ('efe66fb0-01ae-5b35-bb25-40c947777543', 'hi', 'आलू', NULL),
                    ('efe66fb0-01ae-5b35-bb25-40c947777543', 'mr', 'बटाटा', NULL),
                    ('57012511-ab03-538c-a998-e4a1e60ce840', 'en', 'Tomato', NULL),
                    ('57012511-ab03-538c-a998-e4a1e60ce840', 'hi', 'टमाटर', NULL),
                    ('57012511-ab03-538c-a998-e4a1e60ce840', 'mr', 'टोमॅटो', NULL),
                    ('03f33965-9259-50a2-abe2-5d1a21a7ee90', 'en', 'Green Chilli', NULL),
                    ('03f33965-9259-50a2-abe2-5d1a21a7ee90', 'hi', 'हरी मिर्च', NULL),
                    ('03f33965-9259-50a2-abe2-5d1a21a7ee90', 'mr', 'हिरवी मिरची', NULL),
                    ('55b5b6c9-5dc0-5b48-b921-167215e49bea', 'en', 'Wheat', NULL),
                    ('55b5b6c9-5dc0-5b48-b921-167215e49bea', 'hi', 'गेहूं', NULL),
                    ('55b5b6c9-5dc0-5b48-b921-167215e49bea', 'mr', 'गहू', NULL),
                    ('12c60da9-7593-5956-9739-bb71f0c03459', 'en', 'Rice', NULL),
                    ('12c60da9-7593-5956-9739-bb71f0c03459', 'hi', 'चावल', NULL),
                    ('12c60da9-7593-5956-9739-bb71f0c03459', 'mr', 'तांदूळ', NULL),
                    ('30fda377-fb14-5c9f-ac6d-a80e1b7aaf92', 'en', 'Jowar (Sorghum)', NULL),
                    ('30fda377-fb14-5c9f-ac6d-a80e1b7aaf92', 'hi', 'ज्वार', NULL),
                    ('30fda377-fb14-5c9f-ac6d-a80e1b7aaf92', 'mr', 'ज्वारी', NULL),
                    ('abe56060-b038-5d97-948c-eb2914a0e695', 'en', 'Bajra (Pearl Millet)', NULL),
                    ('abe56060-b038-5d97-948c-eb2914a0e695', 'hi', 'बाजरा', NULL),
                    ('abe56060-b038-5d97-948c-eb2914a0e695', 'mr', 'बाजरी', NULL),
                    ('dc1fc82d-ce54-5c06-828a-c0f7e03fefa3', 'en', 'Tur (Arhar)', NULL),
                    ('dc1fc82d-ce54-5c06-828a-c0f7e03fefa3', 'hi', 'अरहर (तुअर)', NULL),
                    ('dc1fc82d-ce54-5c06-828a-c0f7e03fefa3', 'mr', 'तूर', NULL),
                    ('29e4fc7b-0ea7-5fa4-8c8c-7a6c6faeeb38', 'en', 'Chana (Bengal Gram)', NULL),
                    ('29e4fc7b-0ea7-5fa4-8c8c-7a6c6faeeb38', 'hi', 'चना', NULL),
                    ('29e4fc7b-0ea7-5fa4-8c8c-7a6c6faeeb38', 'mr', 'हरभरा', NULL),
                    ('7955b143-95e3-540e-b208-b4939878a972', 'en', 'Moong (Green Gram)', NULL),
                    ('7955b143-95e3-540e-b208-b4939878a972', 'hi', 'मूंग', NULL),
                    ('7955b143-95e3-540e-b208-b4939878a972', 'mr', 'मूग', NULL),
                    ('2f7e8181-4662-5e1f-ae43-cb8bf19fe28d', 'en', 'Urad (Black Gram)', NULL),
                    ('2f7e8181-4662-5e1f-ae43-cb8bf19fe28d', 'hi', 'उड़द', NULL),
                    ('2f7e8181-4662-5e1f-ae43-cb8bf19fe28d', 'mr', 'उडीद', NULL),
                    ('a60ecee4-708c-534e-bd54-7e611da7f553', 'en', 'TMT Steel Bars', NULL),
                    ('a60ecee4-708c-534e-bd54-7e611da7f553', 'hi', 'टीएमटी सरिया', NULL),
                    ('a60ecee4-708c-534e-bd54-7e611da7f553', 'mr', 'टीएमटी सळई', NULL),
                    ('b335f434-90d2-5626-adc5-442eb3c7875d', 'en', 'OPC 53 Grade Cement', NULL),
                    ('b335f434-90d2-5626-adc5-442eb3c7875d', 'hi', 'ओपीसी 53 ग्रेड सीमेंट', NULL),
                    ('b335f434-90d2-5626-adc5-442eb3c7875d', 'mr', 'ओपीसी 53 ग्रेड सिमेंट', NULL),
                    ('cf16678f-f948-5e08-9139-315a91cdf645', 'en', 'PPC Cement', NULL),
                    ('cf16678f-f948-5e08-9139-315a91cdf645', 'hi', 'पीपीसी सीमेंट', NULL),
                    ('cf16678f-f948-5e08-9139-315a91cdf645', 'mr', 'पीपीसी सिमेंट', NULL),
                    ('e3632ccd-6d00-516a-8fd1-7328e93dd84c', 'en', 'Red Clay Brick', NULL),
                    ('e3632ccd-6d00-516a-8fd1-7328e93dd84c', 'hi', 'लाल ईंट', NULL),
                    ('e3632ccd-6d00-516a-8fd1-7328e93dd84c', 'mr', 'लाल वीट', NULL),
                    ('908beb78-128c-5318-afad-de387402e24e', 'en', 'AAC Block', NULL),
                    ('908beb78-128c-5318-afad-de387402e24e', 'hi', 'एएसी ब्लॉक', NULL),
                    ('908beb78-128c-5318-afad-de387402e24e', 'mr', 'एएसी ब्लॉक', NULL),
                    ('d54c248f-bfc2-57f8-84d1-c7c11fc84cc1', 'en', 'River Sand', NULL),
                    ('d54c248f-bfc2-57f8-84d1-c7c11fc84cc1', 'hi', 'नदी की रेत', NULL),
                    ('d54c248f-bfc2-57f8-84d1-c7c11fc84cc1', 'mr', 'नदीची वाळू', NULL),
                    ('d78e5fbd-734f-5ca3-a597-d491dbbe2bf7', 'en', 'M-Sand (Manufactured Sand)', NULL),
                    ('d78e5fbd-734f-5ca3-a597-d491dbbe2bf7', 'hi', 'एम-सैंड (कृत्रिम रेत)', NULL),
                    ('d78e5fbd-734f-5ca3-a597-d491dbbe2bf7', 'mr', 'एम-सँड (कृत्रिम वाळू)', NULL),
                    ('c3d5fdba-a85c-59aa-b620-f89be9d39919', 'en', 'Crushed Aggregate 20 mm', NULL),
                    ('c3d5fdba-a85c-59aa-b620-f89be9d39919', 'hi', 'गिट्टी 20 मिमी', NULL),
                    ('c3d5fdba-a85c-59aa-b620-f89be9d39919', 'mr', 'खडी 20 मिमी', NULL),
                    ('807bca64-9217-5fb9-8952-302db242fee8', 'en', 'Crushed Aggregate 10 mm', NULL),
                    ('807bca64-9217-5fb9-8952-302db242fee8', 'hi', 'गिट्टी 10 मिमी', NULL),
                    ('807bca64-9217-5fb9-8952-302db242fee8', 'mr', 'खडी 10 मिमी', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.product_variants (id, product_id, code, display_order, is_active, created_at_utc, created_by) VALUES
                    ('f24108b3-1d4f-57d5-bcb9-2dce58466907', 'a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'red', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('602d1b11-7f79-5d37-bdbb-7813d05ad821', 'a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'white', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('8c424be6-9ef0-5bca-b658-c08b5fd87ff7', '57012511-ab03-538c-a998-e4a1e60ce840', 'hybrid', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('5100ce12-125a-5024-9204-7af829b096ff', '57012511-ab03-538c-a998-e4a1e60ce840', 'local', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('c763ec1e-db81-56fe-9e66-e2a6585b1f58', 'a60ecee4-708c-534e-bd54-7e611da7f553', 'fe-500', 1, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('a0ba28dc-2d1f-5a3f-b734-b61f7a1f5053', 'a60ecee4-708c-534e-bd54-7e611da7f553', 'fe-500d', 2, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL),
                    ('18df53ad-b845-5f7c-8c6b-e01c144cf359', 'a60ecee4-708c-534e-bd54-7e611da7f553', 'fe-550d', 3, TRUE, TIMESTAMPTZ '2026-09-25 00:00:00+00', NULL);
                """);

            migrationBuilder.Sql("""
                INSERT INTO catalog.product_variant_translations (variant_id, language_code, name, description) VALUES
                    ('f24108b3-1d4f-57d5-bcb9-2dce58466907', 'en', 'Red', NULL),
                    ('f24108b3-1d4f-57d5-bcb9-2dce58466907', 'hi', 'लाल', NULL),
                    ('f24108b3-1d4f-57d5-bcb9-2dce58466907', 'mr', 'लाल', NULL),
                    ('602d1b11-7f79-5d37-bdbb-7813d05ad821', 'en', 'White', NULL),
                    ('602d1b11-7f79-5d37-bdbb-7813d05ad821', 'hi', 'सफ़ेद', NULL),
                    ('602d1b11-7f79-5d37-bdbb-7813d05ad821', 'mr', 'पांढरा', NULL),
                    ('8c424be6-9ef0-5bca-b658-c08b5fd87ff7', 'en', 'Hybrid', NULL),
                    ('8c424be6-9ef0-5bca-b658-c08b5fd87ff7', 'hi', 'हाइब्रिड', NULL),
                    ('8c424be6-9ef0-5bca-b658-c08b5fd87ff7', 'mr', 'संकरित', NULL),
                    ('5100ce12-125a-5024-9204-7af829b096ff', 'en', 'Local', NULL),
                    ('5100ce12-125a-5024-9204-7af829b096ff', 'hi', 'देसी', NULL),
                    ('5100ce12-125a-5024-9204-7af829b096ff', 'mr', 'गावरान', NULL),
                    ('c763ec1e-db81-56fe-9e66-e2a6585b1f58', 'en', 'Fe 500', NULL),
                    ('a0ba28dc-2d1f-5a3f-b734-b61f7a1f5053', 'en', 'Fe 500D', NULL),
                    ('18df53ad-b845-5f7c-8c6b-e01c144cf359', 'en', 'Fe 550D', NULL);
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM catalog.product_variants WHERE id IN ('f24108b3-1d4f-57d5-bcb9-2dce58466907', '602d1b11-7f79-5d37-bdbb-7813d05ad821', '8c424be6-9ef0-5bca-b658-c08b5fd87ff7', '5100ce12-125a-5024-9204-7af829b096ff', 'c763ec1e-db81-56fe-9e66-e2a6585b1f58', 'a0ba28dc-2d1f-5a3f-b734-b61f7a1f5053', '18df53ad-b845-5f7c-8c6b-e01c144cf359');
                """);

            migrationBuilder.Sql("""
                DELETE FROM catalog.products WHERE id IN ('a16ed679-5bf3-5f4e-b867-52e6945dbbe3', 'efe66fb0-01ae-5b35-bb25-40c947777543', '57012511-ab03-538c-a998-e4a1e60ce840', '03f33965-9259-50a2-abe2-5d1a21a7ee90', '55b5b6c9-5dc0-5b48-b921-167215e49bea', '12c60da9-7593-5956-9739-bb71f0c03459', '30fda377-fb14-5c9f-ac6d-a80e1b7aaf92', 'abe56060-b038-5d97-948c-eb2914a0e695', 'dc1fc82d-ce54-5c06-828a-c0f7e03fefa3', '29e4fc7b-0ea7-5fa4-8c8c-7a6c6faeeb38', '7955b143-95e3-540e-b208-b4939878a972', '2f7e8181-4662-5e1f-ae43-cb8bf19fe28d', 'a60ecee4-708c-534e-bd54-7e611da7f553', 'b335f434-90d2-5626-adc5-442eb3c7875d', 'cf16678f-f948-5e08-9139-315a91cdf645', 'e3632ccd-6d00-516a-8fd1-7328e93dd84c', '908beb78-128c-5318-afad-de387402e24e', 'd54c248f-bfc2-57f8-84d1-c7c11fc84cc1', 'd78e5fbd-734f-5ca3-a597-d491dbbe2bf7', 'c3d5fdba-a85c-59aa-b620-f89be9d39919', '807bca64-9217-5fb9-8952-302db242fee8');
                """);

            migrationBuilder.Sql("""
                DELETE FROM catalog.sub_categories WHERE id IN ('0404b99e-b5c6-5b22-9500-ff23e57bd843', '661288ad-c9eb-5859-90dc-d844b957f39c', '974aa1da-6416-5515-b639-be0e5ef74f94', 'e38b0567-3362-527b-bee2-a02507b5ab6d', 'b6db3c71-de05-5a88-9f25-ffe548e3572d', 'd3ea6c72-e23c-5ef4-ab8b-9069d93a7f98', 'c58242c0-e045-5485-8ade-1e7dc41b87f3');
                """);

            migrationBuilder.Sql("""
                DELETE FROM catalog.procurement_categories WHERE id IN ('f161ea3c-9973-5304-84c3-82e0d2ce655b', '245fba83-5854-55b6-a895-87c08b03b820');
                """);

            migrationBuilder.Sql("""
                DELETE FROM catalog.units_of_measure WHERE id IN ('804d9cd5-8fa0-5580-ae2e-035bc10bacda', '9826c24b-8f2c-50e9-8389-9fd99d225462', 'b36af3ca-6c5b-5593-a0f6-743f5e785936', '55dd0941-d052-573a-9fda-309164c490c1', '91fe4f3d-2f39-505f-945e-8a8ff1b231a5', '498d2e87-8f57-5220-bc00-226f7fed8d3e', '135e2afb-812a-5832-8c07-95051ea7437b', '7ed82cbf-53b6-5c73-8758-28c17c65a5de', 'a531b082-21e7-5a76-880b-054b3feeb534', '765d1f58-15c4-58cd-ae34-5c1780540f84', '273a73bf-552c-5783-a0a2-31780fe01cd1', 'ba2ac478-114b-5c1a-bea9-4836d0219185', '57633ab6-89fe-570f-9d05-77453a8bd31f');
                """);
        }
    }
}
