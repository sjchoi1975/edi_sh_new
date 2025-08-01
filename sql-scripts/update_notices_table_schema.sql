-- 공지사항 테이블 스키마 업데이트
-- 1. author_id를 created_by로 변경
ALTER TABLE notices RENAME COLUMN author_id TO created_by;

-- 2. updated_by 컬럼 추가
ALTER TABLE notices ADD COLUMN IF NOT EXISTS updated_by UUID;

-- 3. 기존 created_by가 NULL인 경우 현재 사용자로 설정 (선택사항)
-- UPDATE notices SET created_by = auth.uid() WHERE created_by IS NULL;

-- 4. updated_at 컬럼이 없다면 추가 (이미 있다면 무시)
ALTER TABLE notices ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 5. updated_at 자동 업데이트 트리거 추가 (이미 있다면 무시)
CREATE OR REPLACE FUNCTION update_notices_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 트리거가 없다면 생성
DROP TRIGGER IF EXISTS update_notices_updated_at ON notices;
CREATE TRIGGER update_notices_updated_at
    BEFORE UPDATE ON notices
    FOR EACH ROW
    EXECUTE FUNCTION update_notices_updated_at_column(); 