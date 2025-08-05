-- product_company 관련 테이블 확인
-- 2025-01-07

-- 1. 모든 테이블 목록에서 product_company 관련 테이블 찾기
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name LIKE '%product%company%'
ORDER BY table_name;

-- 2. product_company_not_assignments 테이블이 이미 존재하는지 확인
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND table_name = 'product_company_not_assignments'
);

-- 3. product_company_assignments 테이블이 존재하는지 확인
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND table_name = 'product_company_assignments'
); 