-- 표준코드 데이터 마이그레이션
-- 2025-01-07

-- 1. 기존 products 테이블의 표준코드 데이터를 products_standard_code로 마이그레이션
-- 중복 데이터는 첫 번째 값만 사용
INSERT INTO products_standard_code (
    insurance_code,
    standard_code,
    unit_packaging_desc,
    unit_quantity,
    created_by
)
SELECT DISTINCT ON (p.insurance_code, p.standard_code)
    p.insurance_code,
    p.standard_code,
    p.unit_packaging_desc,
    p.unit_quantity,
    p.created_by
FROM products p
WHERE p.insurance_code IS NOT NULL 
  AND p.standard_code IS NOT NULL
  AND p.insurance_code != ''
  AND p.standard_code != ''
  AND NOT EXISTS (
      SELECT 1 FROM products_standard_code psc
      WHERE psc.insurance_code = p.insurance_code
        AND psc.standard_code = p.standard_code
  )
ORDER BY p.insurance_code, p.standard_code, p.created_at;

-- 2. 마이그레이션 결과 확인
SELECT '마이그레이션 완료' as status;
SELECT COUNT(*) as migrated_records FROM products_standard_code;