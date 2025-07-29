-- updated_at 필드 수정 문제 해결

-- 1. 기존 트리거 삭제 (INSERT 전용이므로 UPDATE에는 영향 없음)
DROP TRIGGER IF EXISTS trigger_set_updated_at_null_on_insert ON public.clients;

-- 2. updated_at 자동 업데이트를 위한 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- UPDATE 시에만 updated_at을 현재 시간으로 설정
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = NOW();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. UPDATE 트리거 생성
DROP TRIGGER IF EXISTS trigger_update_updated_at ON public.clients;

CREATE TRIGGER trigger_update_updated_at
    BEFORE UPDATE ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 4. INSERT 시 updated_at을 NULL로 설정하는 트리거 함수 수정
CREATE OR REPLACE FUNCTION set_updated_at_null_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- 새 레코드 삽입 시 updated_at을 NULL로 설정
    NEW.updated_at = NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. INSERT 트리거 재생성
CREATE TRIGGER trigger_set_updated_at_null_on_insert
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at_null_on_insert();

-- 6. 현재 트리거 상태 확인
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'clients'
ORDER BY trigger_name; 