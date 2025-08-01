-- 공지사항 테이블의 모든 updated_by 컬럼에 사용자 ID 설정

-- 1. 모든 레코드의 updated_by 설정 (NULL이 아닌 경우도 포함)
UPDATE notices 
SET updated_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31';

-- 2. 결과 확인
SELECT 
    id,
    title,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM notices 
ORDER BY created_at DESC; 