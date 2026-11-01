-- MolBhav test markets. Safe to run more than once (skips codes that already exist).
-- District ids are the seeded, deterministic ids (UUIDv5) — identical in every environment.
INSERT INTO market.mandis (id, code, district_id, name, is_active, created_at_utc)
SELECT gen_random_uuid(), v.code, v.district_id::uuid, v.name, TRUE, now()
FROM (VALUES
    ('apmc-pune',        'fcd0f6ea-df2f-5b32-a14b-c93715d08b97', 'Pune APMC (Gultekdi)'),
    ('apmc-lasalgaon',   '5f3c7729-caf2-5b3a-a342-010ab2c5d1d2', 'Lasalgaon APMC'),
    ('apmc-nashik',      '5f3c7729-caf2-5b3a-a342-010ab2c5d1d2', 'Nashik APMC'),
    ('apmc-ahilyanagar', '87fe273a-43b1-5204-9c63-7b8b489b31f2', 'Ahilyanagar APMC'),
    ('apmc-solapur',     '66adbb6a-6658-5630-8a0e-c24240b47839', 'Solapur APMC'),
    ('apmc-vashi',       '00d2c7fa-d724-5174-812c-d7db4d1da8f6', 'Vashi APMC (Navi Mumbai)'),
    ('apmc-nagpur',      'fb95f71e-137d-5dbf-8e26-29be05f16923', 'Nagpur APMC (Kalamna)'),
    ('apmc-kolhapur',    'b87c6693-b01e-5c61-8ce7-9aca2b706040', 'Kolhapur APMC'),
    ('apmc-indore',      '68d9b1b1-d8b5-5499-967d-c452bd325a3f', 'Indore APMC (Choithram)')
) AS v(code, district_id, name)
WHERE NOT EXISTS (SELECT 1 FROM market.mandis m WHERE m.code = v.code);

INSERT INTO market.suppliers (id, code, district_id, name, contact_phone, is_active, created_at_utc)
SELECT gen_random_uuid(), v.code, v.district_id::uuid, v.name, NULL, TRUE, now()
FROM (VALUES
    ('pune-steel-traders',  'fcd0f6ea-df2f-5b32-a14b-c93715d08b97', 'Pune Steel Traders'),
    ('pune-cement-depot',   'fcd0f6ea-df2f-5b32-a14b-c93715d08b97', 'Pune Cement Depot'),
    ('nashik-steel-mart',   '5f3c7729-caf2-5b3a-a342-010ab2c5d1d2', 'Nashik Steel Mart'),
    ('mumbai-build-supply', '00d2c7fa-d724-5174-812c-d7db4d1da8f6', 'Mumbai Build Supply'),
    ('satara-sand-co',      'ea493926-6472-5937-a4bb-49c33b7bb793', 'Satara Sand Co.')
) AS v(code, district_id, name)
WHERE NOT EXISTS (SELECT 1 FROM market.suppliers s WHERE s.code = v.code);

SELECT 'mandis' AS kind, count(*) FROM market.mandis
UNION ALL SELECT 'suppliers', count(*) FROM market.suppliers;
