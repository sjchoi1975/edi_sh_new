-- pharmacies 테이블의 updated_at 값을 모두 NULL로 설정

-- 1. 트리거 일시 비활성화
ALTER TABLE pharmacies DISABLE TRIGGER update_pharmacies_updated_at;

-- 2. 모든 레코드의 updated_at을 NULL로 설정
UPDATE pharmacies 
SET updated_at = NULL,
    updated_by = NULL;

-- 3. 트리거 다시 활성화
ALTER TABLE pharmacies ENABLE TRIGGER update_pharmacies_updated_at;

-- 4. 결과 확인
SELECT 
    id,
    name,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM pharmacies 
ORDER BY created_at DESC; 