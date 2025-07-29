-- clients 테이블에 컬럼 추가 및 updated_at 초기값 문제 해결

-- 1. clients 테이블에 새 컬럼들 추가
ALTER TABLE public.clients 
ADD COLUMN IF NOT EXISTS created_by uuid NULL,
ADD COLUMN IF NOT EXISTS updated_by uuid NULL,
ADD COLUMN IF NOT EXISTS remarks_settlement text NULL;

-- 2. 외래키 제약조건 추가 (PostgreSQL 호환 방식)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'clients_created_by_fkey'
    ) THEN
        ALTER TABLE public.clients 
        ADD CONSTRAINT clients_created_by_fkey 
        FOREIGN KEY (created_by) REFERENCES auth.users(id);
    END IF;
END $$;

DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'clients_updated_by_fkey'
    ) THEN
        ALTER TABLE public.clients 
        ADD CONSTRAINT clients_updated_by_fkey 
        FOREIGN KEY (updated_by) REFERENCES auth.users(id);
    END IF;
END $$;

-- 3. 인덱스 추가
CREATE INDEX IF NOT EXISTS idx_clients_created_by 
ON public.clients USING btree (created_by);

CREATE INDEX IF NOT EXISTS idx_clients_updated_by 
ON public.clients USING btree (updated_by);

-- 4. updated_at 초기값 문제 해결을 위한 트리거 함수 생성
CREATE OR REPLACE FUNCTION set_updated_at_null_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- 새 레코드 삽입 시 updated_at을 NULL로 설정
    NEW.updated_at = NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 5. 트리거 생성 (기존 트리거가 있다면 삭제 후 재생성)
DROP TRIGGER IF EXISTS trigger_set_updated_at_null_on_insert ON public.clients;

CREATE TRIGGER trigger_set_updated_at_null_on_insert
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_updated_at_null_on_insert();

-- 6. 현재 상태 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients'
AND column_name IN ('created_by', 'updated_by', 'remarks_settlement', 'created_at', 'updated_at')
ORDER BY column_name;