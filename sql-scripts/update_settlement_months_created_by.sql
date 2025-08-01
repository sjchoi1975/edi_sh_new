-- settlement_months 테이블의 모든 created_by 컬럼에 사용자 ID 설정

-- 1. 모든 레코드의 created_by를 지정된 사용자 ID로 설정
UPDATE settlement_months 
SET created_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31';

-- 2. 결과 확인
SELECT 
    id,
    settlement_month,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM settlement_months 
ORDER BY created_at DESC; 