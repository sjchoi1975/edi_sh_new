-- products 테이블의 status 값 디버깅
-- 2025-01-07

-- 1. status 컬럼의 현재 기본값 확인
SELECT column_name, column_default, is_nullable, data_type 
FROM information_schema.columns 
WHERE table_name = 'products' AND column_name = 'status';

-- 2. status 값들의 분포 확인
SELECT 
  status,
  COUNT(*) as count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM products), 2) as percentage
FROM products 
GROUP BY status
ORDER BY count DESC;

-- 3. 최근 등록된 제품들의 status 확인 (최근 10개)
SELECT 
  id,
  product_name,
  insurance_code,
  status,
  created_at,
  created_by
FROM products 
ORDER BY created_at DESC 
LIMIT 10;

-- 4. status가 NULL인 레코드 확인
SELECT 
  id,
  product_name,
  insurance_code,
  status,
  created_at
FROM products 
WHERE status IS NULL;

-- 5. status가 'active' 또는 'inactive'가 아닌 레코드 확인
SELECT 
  id,
  product_name,
  insurance_code,
  status,
  created_at
FROM products 
WHERE status NOT IN ('active', 'inactive') AND status IS NOT NULL; 