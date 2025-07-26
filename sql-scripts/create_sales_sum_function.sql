-- 매출액 합계 계산 함수 생성
CREATE OR REPLACE FUNCTION calculate_sales_sum(
  table_name text,
  from_date text DEFAULT NULL,
  to_date text DEFAULT NULL,
  search_keyword text DEFAULT NULL
)
RETURNS numeric
LANGUAGE plpgsql
AS $$
DECLARE
  query_text text;
  result numeric;
BEGIN
  -- 기본 쿼리 시작
  query_text := 'SELECT COALESCE(SUM(sales_amount), 0) FROM ' || table_name || ' WHERE 1=1';
  
  -- 날짜 필터 적용
  IF from_date IS NOT NULL AND to_date IS NOT NULL THEN
    query_text := query_text || ' AND sales_date >= ''' || from_date || ''' AND sales_date <= ''' || to_date || '''';
  ELSIF from_date IS NOT NULL THEN
    query_text := query_text || ' AND sales_date >= ''' || from_date || '''';
  ELSIF to_date IS NOT NULL THEN
    query_text := query_text || ' AND sales_date <= ''' || to_date || '''';
  END IF;
  
  -- 검색 키워드 필터 적용
  IF search_keyword IS NOT NULL THEN
    query_text := query_text || ' AND (pharmacy_name ILIKE ''%' || search_keyword || '%'' OR business_registration_number ILIKE ''%' || search_keyword || '%'' OR standard_code ILIKE ''%' || search_keyword || '%'' OR product_name ILIKE ''%' || search_keyword || '%'')';
  END IF;
  
  -- 쿼리 실행
  EXECUTE query_text INTO result;
  
  RETURN result;
END;
$$; 