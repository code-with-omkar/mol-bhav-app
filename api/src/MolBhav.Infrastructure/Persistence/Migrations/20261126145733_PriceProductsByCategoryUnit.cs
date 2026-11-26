using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace MolBhav.Infrastructure.Persistence.Migrations
{
    /// <summary>
    /// Files farm products under proper sub-categories and prices each in the unit that group is traded in: per kg for
    /// vegetables, fruits, flowers, spices, dry fruits, oils and fish; per quintal for grains, pulses, oilseeds and
    /// other produce. Stored prices (quoted per quintal) of the kg products, and everything users saved against them,
    /// are converted. Live animals are hidden because the feed does not say what their price is per.
    /// </summary>
    public partial class PriceProductsByCategoryUnit : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                CREATE TEMP TABLE new_groups (code text, display_order int, is_active boolean, en text, hi text, mr text) ON COMMIT DROP;
                INSERT INTO new_groups VALUES
                    ('vegetables',    1,  TRUE,  'Vegetables',      'सब्ज़ियाँ',        'भाजीपाला'),
                    ('fruits',        2,  TRUE,  'Fruits',          'फल',              'फळे'),
                    ('grains',        3,  TRUE,  'Grains',          'अनाज',            'धान्य'),
                    ('pulses',        4,  TRUE,  'Pulses',          'दालें',             'कडधान्ये'),
                    ('spices',        5,  TRUE,  'Spices',          'मसाले',            'मसाले'),
                    ('oilseeds',      6,  TRUE,  'Oilseeds',        'तिलहन',           'तेलबिया'),
                    ('flowers',       7,  TRUE,  'Flowers',         'फूल',              'फुले'),
                    ('dry-fruits',    8,  TRUE,  'Dry fruits',      'सूखे मेवे',          'सुका मेवा'),
                    ('oils',          9,  TRUE,  'Oils and ghee',   'तेल और घी',        'तेल आणि तूप'),
                    ('fish',          10, TRUE,  'Fish',            'मछली',            'मासे'),
                    ('other-produce', 11, TRUE,  'Other produce',   'अन्य उपज',         'इतर शेतमाल'),
                    ('livestock',     12, FALSE, 'Live animals',    'पशुधन',            'पशुधन');

                INSERT INTO catalog.sub_categories (id, category_id, code, display_order, is_active, created_at_utc)
                    SELECT md5('sub-category:' || g.code)::uuid, c.id, g.code, g.display_order, g.is_active, now()
                    FROM new_groups g
                    JOIN catalog.procurement_categories c ON c.code = 'agriculture'
                    WHERE NOT EXISTS (SELECT 1 FROM catalog.sub_categories s WHERE s.code = g.code);
                UPDATE catalog.sub_categories s SET display_order = g.display_order, updated_at_utc = now()
                    FROM new_groups g WHERE s.code = g.code;
                INSERT INTO catalog.sub_category_translations (sub_category_id, language_code, name)
                    SELECT s.id, v.lang, v.name
                    FROM new_groups g
                    JOIN catalog.sub_categories s ON s.code = g.code
                    CROSS JOIN LATERAL (VALUES ('en', g.en), ('hi', g.hi), ('mr', g.mr)) v(lang, name)
                    ON CONFLICT DO NOTHING;

                CREATE TEMP TABLE product_groups (group_code text, product_codes text) ON COMMIT DROP;
                INSERT INTO product_groups VALUES
                    ('vegetables', 'alsandikai amaranthus amranthas-red ashgourd baby-corn banana-green beans beetroot bhindi-ladies-finger bitter-gourd bottle-gourd brinjal bunch-beans cabbage capsicum carrot cauliflower chapparad-avare chena chilly-capsicum chow-chow cluster-beans colacasia coriander-leaves cowpea-veg cucumbar-kheera drumstick duster-beans elephant-yam-suran-amorphophallus field-bean-anumulu field-pea french-beans-frasbean garlic ginger-green gram-raw-chholia green-avare-w green-chilli green-peas guar indian-beans-seam knool-khol ladies-finger leafy-vegetable little-gourd-kundru long-melon-kakri mango-raw-ripe methi-leaves mint-pudina mushroom onion onion-green other-green-and-fresh-vegetables papaya-raw pea-pod-pea-cod peas-wet pegeon-pea-arhar-fali pointed-gourd-parval potato pumpkin raddish ridgeguard-tori round-gourd season-leaves seemebadnekai snakeguard spinach spiny-gourd-kartali-kantola sponge-gourd squash-chappal-kadoo sweet-corn sweet-potato sweet-pumpkin tapioca taro-arvi-stem thogrikai thondekai tinda tomato turnip white-pumpkin wild-cucumber yam-ratalu'),
                    ('fruits', 'amla-nelli-kai apple avocado banana ber-zizyphus-borehannu blueberry chikoos-sapota coconut custard-apple-sharifa fig-anjura-anjeer grapes guava jack-fruit-ripe karbuja-musk-melon kinnow kiwi-fruit lemon lime litchi mango mousambi-sweet-lime orange papaya pear-marasebu persimon-japani-fal pineapple plum pomegranate seetapal strawberry tamarind-fruit water-melon'),
                    ('flowers', 'astera carnation gladiolus-cut-flower jarbara jasmine kakada kankambra lilly marigold-calcutta marigold-loose rose-local rose-loose tube-flower tube-rose-loose'),
                    ('spices', 'ajwan betal-leaves black-pepper cardamom chili-red cinamon-dalchini corriander-seed cummin-seed-jeera dry-chillies ginger-dry methi-seeds nigella soanf suva-dill-seed turmeric turmeric-raw'),
                    ('dry-fruits', 'arecanut-betelnut-supari cashewnuts walnut'),
                    ('oils', 'coconut-oil ghee mentha-oil mustard-oil'),
                    ('fish', 'fish prawn'),
                    ('oilseeds', 'castor-seed coconut-seed copra ground-nut-seed groundnut groundnut-pods-raw groundnut-split linseed mustard neem-seed safflower sesamum-sesame-gingelly-til soyabean sunflower-sunflower-seed'),
                    ('grains', 'bajra barley-jau beaten-rice foxtail-millet-navane jowar kodo-millet-varagu kutki maida-atta maize millets paddy-basmati paddy-common paddy-fine-superfine-grade-a ragi-finger-millet rajgir rice rice-fine-superfine-grade-a sabu-dan same-savi wheat wheat-atta'),
                    ('pulses', 'alasande-gram avare-dal bengal-gram-dal-chana-dal big-gram black-gram-dal-urd-dal chana chennangi-dal cowpea-lobia-karamani green-gram-dal-moong-dal kabuli-chana-chickpeas-white kulthi-horse-gram lak-teora lentil-masur-whole masur-dal mataki moath-dal moong other-pulses peas-dry red-gram-split-arhar-dal-tur-dal tur urad'),
                    ('other-produce', 'broomstick-flower-broom buttery cocoa coffee cotton dhaincha firewood guar-seed-cluster-beans-seed gulli gur-jaggery isabgul-psyllium jute mahedi mahua rab-liquid-jaggery-molasses rubber sugar tender-coconut tobacco wood'),
                    ('livestock', 'cock goat');

                CREATE TEMP TABLE placed ON COMMIT DROP AS
                    SELECT unnest(string_to_array(product_codes, ' ')) AS product_code, group_code FROM product_groups;

                UPDATE catalog.products p SET sub_category_id = s.id, updated_at_utc = now()
                    FROM placed x JOIN catalog.sub_categories s ON s.code = x.group_code
                    WHERE p.code = x.product_code;
                UPDATE catalog.products SET is_active = FALSE, updated_at_utc = now() WHERE code IN ('cock', 'goat');

                -- The products that move from a price per quintal to a price per kg.
                CREATE TEMP TABLE per_kg ON COMMIT DROP AS
                    SELECT p.id FROM catalog.products p
                    JOIN placed x ON x.product_code = p.code
                    JOIN catalog.units_of_measure u ON u.id = p.default_unit_id AND u.code = 'quintal'
                    WHERE x.group_code IN ('vegetables', 'fruits', 'flowers', 'spices', 'dry-fruits', 'oils', 'fish');

                UPDATE catalog.products SET default_unit_id = (SELECT id FROM catalog.units_of_measure WHERE code = 'kg'), updated_at_utc = now()
                    WHERE id IN (SELECT id FROM per_kg);

                UPDATE pricing.price_records r SET
                        min_price = round(r.min_price / 100, 4),
                        max_price = round(r.max_price / 100, 4),
                        modal_price = round(r.modal_price / 100, 4),
                        unit_id = (SELECT id FROM catalog.units_of_measure WHERE code = 'kg')
                    WHERE r.product_id IN (SELECT id FROM per_kg)
                      AND r.unit_id = (SELECT id FROM catalog.units_of_measure WHERE code = 'quintal');

                UPDATE alerting.alert_rules SET threshold_price = round(threshold_price / 100, 2)
                    WHERE product_id IN (SELECT id FROM per_kg) AND threshold_price IS NOT NULL;
                UPDATE alerting.alerts SET previous_price = round(previous_price / 100, 4), new_price = round(new_price / 100, 4)
                    WHERE product_id IN (SELECT id FROM per_kg);
                UPDATE alerting.market_opportunities SET
                        home_price = round(home_price / 100, 4),
                        best_price = round(best_price / 100, 4),
                        landed_price = round(landed_price / 100, 4)
                    WHERE product_id IN (SELECT id FROM per_kg);

                -- Saved estimates keep the same weight and the same money, counted in kg.
                UPDATE procurement.procurement_opportunities o SET
                        quantity = o.quantity * 100,
                        unit_price = round(o.unit_price / 100, 2)
                    FROM procurement.procurement_requirements q
                    WHERE q.id = o.requirement_id AND q.product_id IN (SELECT id FROM per_kg);
                UPDATE procurement.procurement_requirements SET
                        quantity = quantity * 100,
                        target_price = round(target_price / 100, 2),
                        unit_id = (SELECT id FROM catalog.units_of_measure WHERE code = 'kg')
                    WHERE product_id IN (SELECT id FROM per_kg);
                """, suppressTransaction: false);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Converting back would round prices a second time; restore a backup instead.
        }
    }
}
