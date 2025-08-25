-- 개발서버 트리거 동기화 스크립트
-- 개발서버: selklngerzfmuvagcvvf
-- 목적: 운영서버와 동일한 트리거 상태로 동기화

-- =====================================================
-- 1. settlement_months 테이블 트리거
-- =====================================================

-- 1-1. 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_settlement_months_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- INSERT 시에는 updated_at을 NULL로 설정
    IF TG_OP = 'INSERT' THEN
        NEW.updated_at = NULL;
        RETURN NEW;
    END IF;
    
    -- UPDATE 시에는 updated_at을 현재 시간으로 설정
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = NOW();
        RETURN NEW;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 1-2. 트리거 생성
DROP TRIGGER IF EXISTS update_settlement_months_updated_at ON settlement_months;
CREATE TRIGGER update_settlement_months_updated_at
    BEFORE INSERT OR UPDATE ON settlement_months
    FOR EACH ROW
    EXECUTE FUNCTION update_settlement_months_updated_at_column();

-- =====================================================
-- 2. 트리거 적용 확인
-- =====================================================

-- 2-1. settlement_months 트리거 확인
SELECT 
    'Settlement Months Trigger Applied' as info,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'settlement_months'
AND trigger_name = 'update_settlement_months_updated_at';

-- 2-2. 전체 트리거 목록 확인
SELECT 
    'All Triggers Status' as info,
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    p.proname as function_name
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
JOIN pg_proc p ON t.tgfoid = p.oid
WHERE n.nspname NOT IN ('information_schema', 'pg_catalog', 'pg_toast')
  AND NOT t.tgisinternal
ORDER BY n.nspname, c.relname, t.tgname;
