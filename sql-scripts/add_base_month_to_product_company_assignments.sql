-- product_company_not_assignments 테이블에 base_month 컬럼 추가
-- 2025-01-07

-- 1. base_month 컬럼 추가
ALTER TABLE product_company_not_assignments 
ADD COLUMN base_month text NOT NULL DEFAULT '2025-08';

-- 2. 기존 데이터의 base_month 업데이트 (products 테이블에서 가져오기)
UPDATE product_company_not_assignments 
SET base_month = p.base_month
FROM products p
WHERE product_company_not_assignments.product_id = p.id;

-- 3. 기본값 제거 (NOT NULL 제약조건 유지)
ALTER TABLE product_company_not_assignments 
ALTER COLUMN base_month DROP DEFAULT;

-- 4. 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_base_month 
ON product_company_not_assignments(base_month);

CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_product_month 
ON product_company_not_assignments(product_id, base_month); 