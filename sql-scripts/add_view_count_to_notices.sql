-- 공지사항 테이블에 조회수 컬럼 추가
ALTER TABLE notices ADD COLUMN IF NOT EXISTS view_count INTEGER DEFAULT 0;

-- 기존 공지사항의 조회수를 0으로 초기화
UPDATE notices SET view_count = 0 WHERE view_count IS NULL;

-- 조회수 컬럼을 NOT NULL로 설정
ALTER TABLE notices ALTER COLUMN view_count SET NOT NULL; 