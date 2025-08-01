-- 공지사항 테이블의 created_by, updated_by 컬럼에 사용자 ID 설정

-- 1. created_by가 NULL인 레코드들의 created_by 설정
UPDATE notices 
SET created_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE created_by IS NULL;

-- 2. updated_by가 NULL이면서 updated_at이 NOT NULL인 레코드들의 updated_by 설정
UPDATE notices 
SET updated_by = '5f474ca1-75e5-4382-b6af-2d33abe54d31'
WHERE updated_by IS NULL 
  AND updated_at IS NOT NULL;

-- 3. 결과 확인
SELECT 
    id,
    title,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM notices 
ORDER BY created_at DESC; 