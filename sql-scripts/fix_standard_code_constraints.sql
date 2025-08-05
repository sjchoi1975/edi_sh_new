-- products_standard_code 테이블의 제약조건 수정
-- 2025-01-07

-- 1. 현재 잘못된 제약조건 삭제 (insurance_code + standard_code 조합)
ALTER TABLE products_standard_code 
DROP CONSTRAINT IF EXISTS products_standard_code_insurance_code_standard_code_key;

-- 2. standard_code만 유니크 제약조건 추가
ALTER TABLE products_standard_code 
ADD CONSTRAINT products_standard_code_standard_code_key UNIQUE (standard_code);

-- 3. 제약조건 확인
SELECT 
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'products_standard_code' 
  AND constraint_type = 'UNIQUE'; 