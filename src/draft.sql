
-- Statistics from file_id=1 (via_full of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 1;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','via','BR-MG-Contagem'))
WHERE file_id = 1;


-- Statistics from file_id=2 (geoaddress_full of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 2;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string2(properties->>'old_via','via','BR-MG-Contagem'))
WHERE file_id = 2;


-- Statistics from file_id=3 (parcel_ext of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_nsvia',properties->>'nsvia')
WHERE file_id = 3;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','parcel','BR-MG-Contagem'))
WHERE file_id = 3;


-- Statistics from file_id=4 (geoaddress_full of 7600002501501 of BR-SP-Jundiai) in ingest.feature_asis.+
UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via','old_postcode',properties->>'postcode', 'old_nsvia',properties->>'nsvia' , 'sup',properties->>'complement')
WHERE file_id = 4;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('postcode',postcode_maskBR(properties->>'old_postcode'))
WHERE file_id = 4;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','geoaddress','BR-SP-Jundiai'))
WHERE file_id = 4;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','geoaddress','BR-SP-Jundiai'))
WHERE file_id = 4;


-- Statistics from file_id=6 (nsvia_full of 7600002501401 of BR-SP-Jundiai) in ingest.feature_asis.+

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_nsvia',properties->>'nsvia')
WHERE file_id = 6;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','nsvia','BR-SP-Jundiai'))
WHERE file_id = 6;

-- Statistics from file_id=7 (via_full of 7600002501201 of BR-SP-Jundiai) in ingest.feature_asis.+

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 7;

UPDATE  ingest.feature_asis
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','via','BR-SP-Jundiai'))
WHERE file_id = 7;



-- ingest.feature_asis_discarded

-- Statistics from file_id=1 (via_full of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 1;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','via','BR-MG-Contagem'))
WHERE file_id = 1;


-- Statistics from file_id=2 (geoaddress_full of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 2;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string2(properties->>'old_via','via','BR-MG-Contagem'))
WHERE file_id = 2;


-- Statistics from file_id=3 (parcel_ext of 7600000901101 of BR-MG-Contagem) in ingest.feature_asis.+
UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_nsvia',properties->>'nsvia')
WHERE file_id = 3;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','parcel','BR-MG-Contagem'))
WHERE file_id = 3;


-- Statistics from file_id=4 (geoaddress_full of 7600002501501 of BR-SP-Jundiai) in ingest.feature_asis.+
UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via','old_postcode',properties->>'postcode', 'old_nsvia',properties->>'nsvia' , 'sup',properties->>'complement')
WHERE file_id = 4;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('postcode',postcode_maskBR(properties->>'old_postcode'))
WHERE file_id = 4;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','geoaddress','BR-SP-Jundiai'))
WHERE file_id = 4;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','geoaddress','BR-SP-Jundiai'))
WHERE file_id = 4;


-- Statistics from file_id=6 (nsvia_full of 7600002501401 of BR-SP-Jundiai) in ingest.feature_asis.+

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_nsvia',properties->>'nsvia')
WHERE file_id = 6;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('nsvia',clean_string(properties->>'old_nsvia','nsvia','BR-SP-Jundiai'))
WHERE file_id = 6;

-- Statistics from file_id=7 (via_full of 7600002501201 of BR-SP-Jundiai) in ingest.feature_asis.+

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('old_via',properties->>'via')
WHERE file_id = 7;

UPDATE  ingest.feature_asis_discarded
SET properties = COALESCE (properties,'{}'::JSONB) || jsonb_build_object('via',clean_string(properties->>'old_via','via','BR-SP-Jundiai'))
WHERE file_id = 7;



-- Por padrão não é gerado kx_ghs9 em feature_asis_discarded. Inicialmente essa tabela seria uma 'lixeira' sem usar as geometrias dessa tabela para publicação. Nem sempre é possivel calcular kx_ghs9 para uma geometria nessa tabela. Sem kx_ghs9 não é possível publicar no CutGeo. O Update a seguir gera kx_ghs9 para as possíveis.

UPDATE ingest.feature_asis_discarded SET kx_ghs9 = f(geom,1::bigint,9)
