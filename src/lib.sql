CREATE or replace FUNCTION postcode_maskBR(
    p_string text
) RETURNS text AS $$
  SELECT
        CASE
        WHEN length(s) = 8 THEN        substring(s FROM 1 FOR 5) || '-' || substring(s FROM 6 FOR 3)
        WHEN length(s) = 7 THEN '0' || substring(s FROM 1 FOR 5) || '-' || substring(s FROM 5 FOR 3)
        ELSE s
        END
  FROM (SELECT regexp_replace(trim(p_string), '[^0-9]', '','g')) t(s)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION postcode_maskBR(text)
  IS 'Apply the mask XXXXX-XXX in the Brazilian postal code.'
;

CREATE or replace FUNCTION initcap2(
    p_string text
) RETURNS text AS $$
  SELECT string_agg((
        CASE
        WHEN lower(p) IN ('da','de','do','das','dos','e','o','as','os','com','ou') AND n <> 1 AND n <> t THEN lower(p)
        ELSE initcap(p)
        END)
    ,' ')
  FROM
  (
    SELECT p, row_number() over () as n, count(*) over () as t
    FROM regexp_split_to_table($1,' ') t(p)
  ) r
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION initcap2(text)
  IS 'Capitalize words that are not prepositions, articles and connectives.'
;

CREATE or replace FUNCTION clean_string_before(
    p_string text
) RETURNS text AS $$
  SELECT trim(regexp_replace( regexp_replace( trim(p_string), '( ){2,}', ' ', 'g' ), E'[\\n\\r]+', ' ', 'g' ))
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string_before(text)
  IS 'Clean string'
;

CREATE or replace FUNCTION clean_string_after(
    p_string text
) RETURNS text AS $$
  SELECT trim(regexp_replace(p_string,'\.(?=[a-zA-Z])','. ','g'))
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string_after(text)
  IS 'Clean string'
;

CREATE or replace FUNCTION rm_abbrev(
    p_string text,
    p_layer text,
    p_isolabel text
) RETURNS text AS $$
  SELECT string_agg((
        CASE
        WHEN nabrrev IS NOT NULL THEN nabrrev
        ELSE p
        END)
    ,' ')
  FROM
  (
    SELECT p, row_number() over () as n, count(*) over () as t
    FROM regexp_split_to_table($1,' ') t(p)
  ) r
  LEFT JOIN abbrevconsolidado s
  ON s.layer=p_layer AND s.field=r.n AND lower(s.abbrev)=lower(r.p) AND s.isolabel_ext=p_isolabel
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION rm_abbrev(text,text,text)
  IS ''
;

CREATE or replace FUNCTION tr_dicio(
    p_isolabel text,
    p_string text
) RETURNS text AS $$
  SELECT COALESCE((SELECT new
  FROM abbrevdicio s
  WHERE  s.old = p_string AND s.isolabel_ext=p_isolabel),p_string)
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION tr_dicio(text,text)
  IS ''
;
-- SELECT tr_dicio('BR-MG-Contagem','Alameda Alameda dos Judiciarios');
-- SELECT tr_dicio('BR-MG-Contagem','Alameda  dos Judiciarios');

CREATE or replace FUNCTION clean_hnum(
    p_string text
) RETURNS text AS $$
  SELECT NULLIF(regexp_replace( clean_string_before(p_string), '^(0+\.?0*|\.0+)$', '', 'g' ),'')
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string_before(text)
  IS 'Clean string'
;

CREATE or replace FUNCTION clean_via(
    p_string text,
    p_layer text,
    p_isolabel text
) RETURNS text AS $$
  SELECT
    CASE
    WHEN p_isolabel = 'BR-MG-Contagem' THEN tr_dicio(p_isolabel,(clean_string_after(initcap2(rm_abbrev(clean_string_before(p_string),p_layer,p_isolabel)))))
    ELSE clean_string_after(initcap2(rm_abbrev(clean_string_before(p_string),p_layer,p_isolabel)))
    END
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string2(text,text,text)
  IS 'Clean string'
;
-- SELECT clean_via('Alameda Alameda dos Judiciarios','geoaddress','BR-MG-Contagem');

-----------------------

CREATE or replace FUNCTION split_via_name(
    p_string text,
    p_isolabel text
) RETURNS text[] AS $$
  SELECT
    CASE
    WHEN p_isolabel = 'BR-PI-Teresina'      THEN (SELECT regexp_matches(p_string, '^(Acesso|Alameda|Avenida|Beco|Conjunto|Estrada|Galeria|Praca|Rodovia|Rua|Travessa|Via) (.*)$'))::text[]
    WHEN p_isolabel = 'BR-MG-BeloHorizonte' THEN (SELECT regexp_matches(p_string, '^(Acesso|Alameda|Avenida|Beco|Espaço Livre para Pedestre|Estrada|Largo|Praça|Rua de Pedestre|Rodovia|Rua|Trevo|Trincheira|Travessa|Via|Via de Pedestre|Viaduto) (.*)$'))::text[]
    WHEN p_isolabel = 'BR-CE-Fortaleza'     THEN (SELECT regexp_matches(p_string, '^(Alameda|Avenida|Beco|Estrada|Galeria|Largo|Praça|Rodovia|Rua|Travessa|Via|Viaduto|Vila) (.*)$'))::text[]
    WHEN p_isolabel = 'BR-MG-Contagem'      THEN (SELECT regexp_matches(p_string, '^(Alameda Alameda|Rua Alameda|Via Acesso|Via Arterial|Via Expressa|Via Municipal|Via Via Expressa|Alameda|Avenida|Beco|Estrada|Praça|Rodovia|Rua|Travessa|Via) (.*)$'))
    WHEN p_isolabel = 'BR-SP-Jundiai'       THEN (SELECT regexp_matches(p_string, '^(Avenida Marginal|Cm Servidao|Estrada Municipal|Estrada Servidao|Travessa Part|Travessa Particular|Via Alca de Acesso|Via Circulacao|Via Pedestre|Via de Pedestre|Via de Pedestres|Alameda|Avenida|Cm|Estrada|Praça|Rodovia|Rua|Travessa|Via|Viaduto|Vp) (.*)$'))
    ELSE ARRAY[null,p_string]
    END
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION split_via_name(text,text)
  IS ''
;

-----------------------


CREATE or replace FUNCTION optim.consolidated_data_ins(
  p_isolabel_ext  text  -- e.g. 'BR-MG-BeloHorizonte', see jurisdiction_geom
) RETURNS text  AS $f$

  INSERT INTO optim.consolidated_data
  SELECT id, afa_id, via_name, via_type, house_number, postcode, geom_frontparcel, score, geom
  FROM
  (
    SELECT rank() OVER (PARTITION BY afa_id ORDER BY house_number DESC, geom) AS id_rank, *
    FROM
    (
      SELECT id,
            natcod.vBit_to_hBig
            (
              CASE jurisd_base_id
                WHEN 76 THEN 1::bit(8)||natcod.baseh_to_vbit(osmc.decode_16h1c(afacodes_scientific,split_part(isolabel_ext,'-',1)),16)
                -- ELSE         natcod.baseh_to_vbit(                  afacodes_scientific      ,16)
              END
            ) AS afa_id,
            arr[1] AS via_type, arr[2] AS via_name,
            house_number, postcode, geom_frontparcel, score, geom
      FROM
      (
        SELECT
          p.id, jurisd_base_id, split_via_name(clean_via(via_name,(q.ftype_info->>'class_ftname')::text,q.isolabel_ext),q.isolabel_ext) AS arr,
          clean_hnum(house_number) AS house_number, q.isolabel_ext,

          CASE jurisd_base_id
            WHEN 76 THEN postcode_maskBR(postcode)
            -- WHEN 'CM' THEN
          END AS postcode,

          (((
          CASE jurisd_base_id
            WHEN 76 THEN osmc.encode_scientific_br(ST_Transform(geom,952019),0.0,0)
            -- WHEN 'CM' THEN
          END
          )->'features')[0]->'properties'->>'code')::text AS afacodes_scientific,

          geom_frontparcel,score,geom,

            CASE housenumber_system_type
            -- address: [via], [hnum]
            WHEN 'metric' THEN
              ROW_NUMBER() OVER(ORDER BY via_name, to_bigint(house_number))
            WHEN 'bh-metric' THEN
              ROW_NUMBER() OVER(ORDER BY via_name, to_bigint(regexp_replace(house_number, '\D', '', 'g')), regexp_replace(house_number, '[^[:alpha:]]', '', 'g') )
            WHEN 'street-metric' THEN
              ROW_NUMBER() OVER(ORDER BY via_name, regexp_replace(house_number, '[^[:alnum:]]', '', 'g'))
            WHEN 'block-metric' THEN
              ROW_NUMBER() OVER(ORDER BY via_name, to_bigint(split_part(replace(house_number,' ',''), '-', 1)), to_bigint(split_part(replace(house_number,' ',''), '-', 2)))

              -- address: [via], [hnum], [sup     ]
              --          [via], [hnum], [[quadra], [lote]]
            WHEN 'ago-block' THEN
              ROW_NUMBER() OVER(ORDER BY via_name, to_bigint(house_number), to_bigint(split_part(postcode, ',', 1)), to_bigint(split_part(postcode, ',', 2)) )

            -- address: [via], [sup]
            --          [[quadra], [lote]], [sup]
            WHEN 'df-block' THEN
              ROW_NUMBER() OVER(ORDER BY split_part(via_name, ',', 1),split_part(via_name, ',', 2),postcode)

            ELSE
              ROW_NUMBER() OVER(ORDER BY via_name, to_bigint(house_number))
            END AS address_order

        FROM optim.consolidated_data_pre p
        LEFT JOIN optim.vw01full_donated_packcomponent q
        ON p.id = q.id_component
        WHERE q.isolabel_ext= p_isolabel_ext
      ) m
    ) x
  ) y
  WHERE id_rank = 1
  ORDER BY 2
  ;
  SELECT 'ins';
$f$ language SQL VOLATILE;
