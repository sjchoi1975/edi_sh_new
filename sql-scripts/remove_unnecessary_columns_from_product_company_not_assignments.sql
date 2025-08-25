-- product_company_not_assignments 테이블에서 불필요한 컬럼 제거
-- base_month, is_active 컬럼을 제거하고 필요한 컬럼만 남김

-- 1. is_active 컬럼 제거
ALTER TABLE product_company_not_assignments DROP COLUMN IF EXISTS is_active;

-- 2. base_month 컬럼 제거
ALTER TABLE product_company_not_assignments DROP COLUMN IF EXISTS base_month;

-- 3. 테이블 구조 확인
-- 남은 컬럼들: id, product_id, company_id, created_at, created_by, updated_at

-- 4. 인덱스 확인 및 재생성 (필요시)
-- product_id와 company_id에 대한 인덱스가 있는지 확인
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_product_id 
ON product_company_not_assignments(product_id);

CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_company_id 
ON product_company_not_assignments(company_id);

-- 5. 복합 인덱스 생성 (product_id, company_id)
CREATE INDEX IF NOT EXISTS idx_product_company_not_assignments_product_company 
ON product_company_not_assignments(product_id, company_id);

-- 6. 테이블 구조 확인을 위한 쿼리
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'product_company_not_assignments' 
AND table_schema = 'public'
ORDER BY ordinal_position; 