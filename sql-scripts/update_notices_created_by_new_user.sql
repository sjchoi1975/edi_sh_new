-- 공지사항 테이블의 created_by 컬럼을 새로운 사용자 ID로 변경

-- 1. 모든 레코드의 created_by를 새로운 사용자 ID로 설정
UPDATE notices 
SET created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a';

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