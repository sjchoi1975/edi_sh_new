-- products_standard_code 테이블 트리거 수정
-- 목적: 
-- 1. INSERT 시 updated_at을 NULL로 설정
-- 2. UPDATE 시 updated_at과 updated_by를 올바르게 설정

-- 1. updated_at 기본값 제거 (INSERT 시 NULL이 되도록)
ALTER TABLE products_standard_code ALTER COLUMN updated_at DROP DEFAULT;

-- 2. 기존 트리거 삭제
DROP TRIGGER IF EXISTS trigger_update_products_standard_code_updated_at ON products_standard_code;
DROP TRIGGER IF EXISTS trigger_set_products_standard_code_updated_at_null_on_insert ON products_standard_code;
DROP TRIGGER IF EXISTS trigger_update_products_standard_code_updated_fields ON products_standard_code;

-- 3. INSERT 시 updated_at을 NULL로 설정하는 트리거 함수
CREATE OR REPLACE FUNCTION set_products_standard_code_updated_at_null_on_insert()
RETURNS TRIGGER AS $$
BEGIN
    -- 새 레코드 삽입 시 updated_at을 NULL로 설정
    NEW.updated_at = NULL;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. INSERT 트리거 생성
CREATE TRIGGER trigger_set_products_standard_code_updated_at_null_on_insert
    BEFORE INSERT ON products_standard_code
    FOR EACH ROW
    EXECUTE FUNCTION set_products_standard_code_updated_at_null_on_insert();

-- 5. UPDATE 시 updated_at과 updated_by를 설정하는 트리거 함수
CREATE OR REPLACE FUNCTION update_products_standard_code_updated_fields()
RETURNS TRIGGER AS $$
BEGIN
    -- UPDATE 시에만 updated_at을 현재 시간으로 설정
    IF TG_OP = 'UPDATE' THEN
        NEW.updated_at = NOW();
        -- updated_by는 클라이언트에서 설정하도록 함 (auth.uid() 사용)
        IF NEW.updated_by IS NULL THEN
            NEW.updated_by = auth.uid();
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 6. UPDATE 트리거 생성
CREATE TRIGGER trigger_update_products_standard_code_updated_fields
    BEFORE UPDATE ON products_standard_code
    FOR EACH ROW
    EXECUTE FUNCTION update_products_standard_code_updated_fields();

-- 7. 현재 트리거 상태 확인
SELECT 
    'Trigger Status for products_standard_code' as info,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'products_standard_code'
ORDER BY trigger_name;

-- 8. 테이블 스키마 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'products_standard_code'
ORDER BY ordinal_position; 