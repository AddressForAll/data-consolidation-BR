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
  SELECT regexp_replace( clean_string_before(p_string), '^(0+\.?0*|\.0+)$', '', 'g' )
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
    WHEN p_isolabel = 'BR-CE-Fortaleza' THEN (SELECT regexp_matches(p_string, '^(Alameda|Avenida|Beco|Estrada|Galeria|Largo|Praça|Rodovia|Rua|Travessa|Via|Viaduto|Vila) (.*)$'))::text[]
    WHEN p_isolabel = 'BR-MG-Contagem'  THEN (SELECT regexp_matches(p_string, '^(Alameda Alameda|Rua Alameda|Via Acesso|Via Arterial|Via Expressa|Via Municipal|Via Via Expressa|Alameda|Avenida|Beco|Estrada|Praça|Rodovia|Rua|Travessa|Via) (.*)$'))
    WHEN p_isolabel = 'BR-SP-Jundiai'   THEN (SELECT regexp_matches(p_string, '^(Avenida Marginal|Cm Servidao|Estrada Municipal|Estrada Servidao|Travessa Part|Travessa Particular|Via Alca de Acesso|Via Circulacao|Via Pedestre|Via de Pedestre|Via de Pedestres|Alameda|Avenida|Cm|Estrada|Praça|Rodovia|Rua|Travessa|Via|Viaduto|Vp) (.*)$'))
    ELSE ARRAY[null,p_string]
    END
$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION split_via_name(text,text)
  IS ''
;
