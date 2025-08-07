-- 사용자 설정 테이블 생성
CREATE TABLE IF NOT EXISTS user_preferences (
    id SERIAL PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    preference_key VARCHAR(100) NOT NULL,
    preference_value TEXT NOT NULL,
    settlement_month_id INTEGER REFERENCES settlement_months(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, preference_key, settlement_month_id)
);

-- settlement_month_id 컬럼이 없다면 추가
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'user_preferences' 
        AND column_name = 'settlement_month_id'
    ) THEN
        ALTER TABLE user_preferences ADD COLUMN settlement_month_id INTEGER REFERENCES settlement_months(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 기존 유니크 제약조건 삭제 (있다면)
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_preference_key_key;

-- 새로운 유니크 제약조건 추가
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_preference_key_settlement_month_id_key 
    UNIQUE(user_id, preference_key, settlement_month_id);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_key ON user_preferences(preference_key);

-- RLS 정책 설정
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- 기존 정책 삭제 (있다면)
DROP POLICY IF EXISTS "Users can view own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can insert own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can update own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can delete own preferences" ON user_preferences;

-- 사용자는 자신의 설정만 조회/수정 가능
CREATE POLICY "Users can view own preferences" ON user_preferences
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences" ON user_preferences
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences" ON user_preferences
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own preferences" ON user_preferences
    FOR DELETE USING (auth.uid() = user_id);

-- updated_at 자동 업데이트를 위한 트리거 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 기존 트리거 삭제 (있다면)
DROP TRIGGER IF EXISTS update_user_preferences_updated_at ON user_preferences;

-- 트리거 생성
CREATE TRIGGER update_user_preferences_updated_at 
    BEFORE UPDATE ON user_preferences 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- 테이블 설명 추가
COMMENT ON TABLE user_preferences IS '사용자별 개인 설정 저장 테이블';
COMMENT ON COLUMN user_preferences.user_id IS '사용자 ID';
COMMENT ON COLUMN user_preferences.preference_key IS '설정 키 (예: hide_notice_modal_performance)';
COMMENT ON COLUMN user_preferences.preference_value IS '설정 값 (JSON 형태 또는 단순 문자열)';
COMMENT ON COLUMN user_preferences.settlement_month_id IS '정산월 ID (월별 설정 구분용)'; 