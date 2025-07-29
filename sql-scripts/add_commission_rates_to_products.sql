-- products 테이블에 commission_rate_d, commission_rate_e 컬럼 추가

-- 1. commission_rate_d 컬럼 추가 (commission_rate_a, commission_rate_b와 동일한 속성)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS commission_rate_d numeric DEFAULT 0;

-- 2. commission_rate_e 컬럼 추가 (commission_rate_a, commission_rate_b와 동일한 속성)
ALTER TABLE public.products 
ADD COLUMN IF NOT EXISTS commission_rate_e numeric DEFAULT 0;

-- 3. 컬럼 속성 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    numeric_precision,
    numeric_scale
FROM information_schema.columns 
WHERE table_name = 'products'
AND column_name IN ('commission_rate_a', 'commission_rate_b', 'commission_rate_c', 'commission_rate_d', 'commission_rate_e')
ORDER BY column_name;

-- 4. 샘플 데이터 확인 (처음 5개 레코드)
SELECT 
    id,
    product_name,
    commission_rate_a,
    commission_rate_b,
    commission_rate_c,
    commission_rate_d,
    commission_rate_e
FROM public.products 
ORDER BY id 
LIMIT 5; 