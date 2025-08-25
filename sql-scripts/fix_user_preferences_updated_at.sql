-- user_preferences 테이블의 updated_at 컬럼 문제 해결
-- 최초 생성 시 updated_at이 NULL이 되도록 트리거 수정

-- 1. 기존 트리거 삭제
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;

-- 2. 트리거 함수 수정 (INSERT 시에는 updated_at을 설정하지 않음)
CREATE OR REPLACE FUNCTION update_user_preferences_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    -- UPDATE 시에만 updated_at 설정
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. 트리거 재생성 (UPDATE 시에만 동작)
CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_user_preferences_updated_at();

-- 4. 기존 데이터에서 최초 생성된 레코드의 updated_at을 NULL로 설정
UPDATE user_preferences 
SET updated_at = NULL 
WHERE created_at = updated_at;

-- 5. 확인
SELECT 
    id,
    preference_key,
    preference_value,
    created_at,
    updated_at
FROM user_preferences 
ORDER BY created_at DESC 
LIMIT 5; 