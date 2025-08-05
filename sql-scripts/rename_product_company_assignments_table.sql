-- product_company_assignments 테이블을 product_company_not_assignments로 이름 변경
-- 2025-01-07

-- 1. 테이블 이름 변경
ALTER TABLE product_company_assignments 
RENAME TO product_company_not_assignments;

-- 2. 인덱스 이름 변경 (있다면)
ALTER INDEX IF EXISTS idx_product_company_assignments_base_month 
RENAME TO idx_product_company_not_assignments_base_month;

ALTER INDEX IF EXISTS idx_product_company_assignments_product_month 
RENAME TO idx_product_company_not_assignments_product_month;

-- 3. 권한 설정 (필요한 경우)
GRANT ALL ON product_company_not_assignments TO authenticated; 