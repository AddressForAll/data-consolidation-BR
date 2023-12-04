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

CREATE or replace FUNCTION clean_string(
    p_string text,
    p_layer text,
    p_isolabel text
) RETURNS text AS $$
    -- remove new lines
    SELECT initcap2(rm_abbrev(trim(regexp_replace(x, E'[\\n\\r]+', ' ', 'g' )),p_layer,p_isolabel))
    FROM
    (
        -- remove spaces
        SELECT regexp_replace(trim(p_string), '( ){2,}', ' ', 'g')
    ) a (x)

$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string(text,text,text)
  IS 'Clean string'
;

CREATE or replace FUNCTION clean_string2(
    p_string text,
    p_layer text,
    p_isolabel text
) RETURNS text AS $$
    -- remove new lines
    SELECT initcap2
           (
            rm_abbrev
            (
              trim(
              regexp_replace(
                regexp_replace(x, E'[\\n\\r]+', ' ', 'g' ),'\.(?=[a-zA-Z])','. ','g')
              ),
              p_layer,
              p_isolabel
            )
           )
    FROM
    (
        -- remove spaces
        SELECT regexp_replace(trim(p_string), '( ){2,}', ' ', 'g')
    ) a (x)

$$ LANGUAGE SQL IMMUTABLE;
COMMENT ON FUNCTION clean_string2(text,text,text)
  IS 'Clean string'
;
