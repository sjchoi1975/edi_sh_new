-- 공지사항 테이블 트리거 완전 분리
-- INSERT와 UPDATE를 별도 트리거로 분리

-- 1. 기존 트리거 완전 삭제
DROP TRIGGER IF EXISTS update_notices_updated_at ON notices;
DROP FUNCTION IF EXISTS update_notices_updated_at_column();

-- 2. UPDATE 전용 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_notices_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. UPDATE 전용 트리거만 생성 (INSERT는 제외)
CREATE TRIGGER update_notices_updated_at
    BEFORE UPDATE ON notices
    FOR EACH ROW
    EXECUTE FUNCTION update_notices_updated_at_column(); 