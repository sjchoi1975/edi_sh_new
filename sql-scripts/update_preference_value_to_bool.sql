-- user_preferences 테이블의 preference_value 컬럼을 text에서 bool로 변경
-- 기존 데이터가 'true'/'false' 문자열로 저장되어 있으므로 이를 boolean으로 변환

-- 1. 기존 데이터 백업 (선택사항)
CREATE TABLE IF NOT EXISTS user_preferences_backup AS 
SELECT * FROM user_preferences;

-- 2. preference_value 컬럼을 bool로 변경
ALTER TABLE user_preferences 
ALTER COLUMN preference_value TYPE BOOLEAN 
USING CASE 
    WHEN preference_value = 'true' THEN true
    WHEN preference_value = 'false' THEN false
    ELSE false  -- 기본값
END;

-- 3. 컬럼 설명 업데이트
COMMENT ON COLUMN user_preferences.preference_value IS '설정 값 (boolean)';

-- 4. 변경 확인
SELECT 
    preference_key, 
    preference_value, 
    pg_typeof(preference_value) as data_type
FROM user_preferences 
LIMIT 5; 