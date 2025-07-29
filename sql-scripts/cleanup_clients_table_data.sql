-- clients 테이블 데이터 정리 스크립트

-- 1. updated_at, updated_by 정보 모두 지우기
UPDATE public.clients 
SET 
    updated_at = NULL,
    updated_by = NULL;

-- 2. 비어있는 created_by에 특정 값 일괄 입력
UPDATE public.clients 
SET created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a'
WHERE created_by IS NULL;

-- 3. 변경 결과 확인
SELECT 
    COUNT(*) as total_records,
    COUNT(created_by) as records_with_created_by,
    COUNT(updated_at) as records_with_updated_at,
    COUNT(updated_by) as records_with_updated_by
FROM public.clients;

-- 4. 샘플 데이터 확인 (처음 5개 레코드)
SELECT 
    id,
    name,
    created_by,
    created_at,
    updated_by,
    updated_at
FROM public.clients 
ORDER BY id 
LIMIT 5; 