-- 기존 공지사항 데이터 최종 정리
-- created_at과 updated_at이 동일한 경우 updated_at을 NULL로 설정

-- 1. 트리거 일시 비활성화
ALTER TABLE notices DISABLE TRIGGER update_notices_updated_at;

-- 2. created_at과 updated_at이 동일한 레코드들의 updated_at을 NULL로 설정
UPDATE notices 
SET updated_at = NULL,
    updated_by = NULL
WHERE created_at IS NOT NULL 
  AND updated_at IS NOT NULL 
  AND DATE_TRUNC('second', created_at) = DATE_TRUNC('second', updated_at);

-- 3. 트리거 다시 활성화
ALTER TABLE notices ENABLE TRIGGER update_notices_updated_at;

-- 4. 결과 확인
SELECT 
    id,
    title,
    created_at,
    updated_at,
    created_by,
    updated_by
FROM notices 
ORDER BY created_at DESC; 