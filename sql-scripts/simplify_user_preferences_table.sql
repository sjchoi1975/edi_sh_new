-- user_preferences 테이블 단순화
-- preference_value와 updated_at 컬럼 삭제

-- 1. 기존 데이터 백업
CREATE TABLE IF NOT EXISTS user_preferences_backup_simplify AS 
SELECT * FROM user_preferences;

-- 2. 기존 트리거 삭제
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;

-- 3. 트리거 함수는 다른 테이블에서도 사용되므로 삭제하지 않음
-- DROP FUNCTION IF EXISTS update_updated_at_column();

-- 4. updated_at 컬럼 삭제
ALTER TABLE user_preferences DROP COLUMN IF EXISTS updated_at;

-- 5. preference_value 컬럼 삭제
ALTER TABLE user_preferences DROP COLUMN IF EXISTS preference_value;

-- 6. 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_preferences'
ORDER BY ordinal_position;

-- 7. 최종 테이블 구조
-- user_preferences 테이블은 이제 다음 컬럼만 가집니다:
-- - id (SERIAL PRIMARY KEY)
-- - user_id (UUID, FK to auth.users)
-- - preference_key (VARCHAR(100))
-- - settlement_month_id (INTEGER, FK to settlement_months)
-- - created_at (TIMESTAMP WITH TIME ZONE)
-- - UNIQUE(user_id, preference_key, settlement_month_id)

-- 8. 테이블 설명 업데이트
COMMENT ON TABLE user_preferences IS '사용자별 개인 설정 저장 테이블 (단순화됨)';
COMMENT ON COLUMN user_preferences.user_id IS '사용자 ID';
COMMENT ON COLUMN user_preferences.preference_key IS '설정 키 (예: hide_notice_modal_performance)';
COMMENT ON COLUMN user_preferences.settlement_month_id IS '정산월 ID (월별 설정 구분용)';
COMMENT ON COLUMN user_preferences.created_at IS '생성 시각';

-- 9. 변경 확인
SELECT 
    'Table simplified successfully' as status,
    COUNT(*) as total_records
FROM user_preferences; 