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
  ON s.layer=p_layer AND s.field=r.n AND s.abbrev=r.p AND s.isolabel_ext=p_isolabel
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION rm_abbrev(text,text,text)
  IS ''
;

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
    SELECT clean_string_after(initcap2(rm_abbrev(clean_string_before(p_string),p_layer,p_isolabel)))
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string2(text,text,text)
  IS 'Clean string'
;

-----------------------

CREATE or replace FUNCTION split_via_name(
    p_string text,
    p_isolabel text
) RETURNS text[] AS $$
  SELECT
    CASE
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
  SELECT isolabel_ext,iso1,iso2,city_name,arr[1] AS via_type,arr[2] AS via_name,house_number,postcode,
        license_family,latitude,longitude,
        afa_id,iso1 || '+' || afacodes_scientific AS afacodes_scientific,afacodes_logistic,
        geom_frontparcel,score,packvers_id,ftid,geom
  FROM
  (
    SELECT p.isolabel_ext,iso1,iso2,city_name,

      split_via_name(clean_via(via_name,(q.info->>'class_ftname')::text,p.isolabel_ext),p.isolabel_ext) AS arr,
      clean_hnum(house_number) AS house_number,

      CASE iso1
      WHEN 'BR' THEN postcode_maskBR(postcode)
      -- WHEN 'CM' THEN
      END AS postcode,

      license_family,latitude,longitude,afa_id,

      (((
      CASE iso1
      WHEN 'BR' THEN osmc.encode_scientific_br(ST_Transform(geom,952019),0.0,0)
      -- WHEN 'CM' THEN
      END
      )->'features')[0]->'properties'->>'code')::text AS afacodes_scientific,

      afacodes_logistic,geom_frontparcel,score,packvers_id,p.ftid,geom,

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
    LEFT JOIN optim.vw01info_feature_type q
    ON p.ftid = q.ftid
    LEFT JOIN optim.jurisdiction r
    ON r.isolabel_ext = p.isolabel_ext
    WHERE p.isolabel_ext=p_isolabel_ext
    ORDER BY isolabel_ext, via_type, via_name, house_number
    -- LIMIT 100
  ) m
  ORDER BY address_order
  ;

  SELECT 'ins';
$f$ language SQL VOLATILE;
