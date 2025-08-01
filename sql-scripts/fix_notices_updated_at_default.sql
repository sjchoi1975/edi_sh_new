-- 공지사항 테이블 updated_at 컬럼의 DEFAULT NOW() 제거
-- INSERT 시 자동으로 시간이 들어가지 않도록 수정

-- 1. updated_at 컬럼의 DEFAULT 제거
ALTER TABLE notices ALTER COLUMN updated_at DROP DEFAULT;

-- 2. 기존 데이터에서 created_at과 동일한 updated_at을 NULL로 설정
UPDATE notices 
SET updated_at = NULL,
    updated_by = NULL
WHERE created_at IS NOT NULL 
  AND updated_at IS NOT NULL 
  AND DATE_TRUNC('second', created_at) = DATE_TRUNC('second', updated_at);

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