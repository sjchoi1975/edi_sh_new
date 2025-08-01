-- products 테이블 트리거 수정
-- status 변경 시에는 updated_at, updated_by를 설정하지 않도록 수정

CREATE OR REPLACE FUNCTION update_products_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    -- INSERT 시에는 updated_at, updated_by 설정하지 않음
    IF TG_OP = 'INSERT' THEN
        RETURN NEW;
    END IF;
    
    -- UPDATE 시에만 처리
    IF TG_OP = 'UPDATE' THEN
        -- status가 변경된 경우 updated_at, updated_by 업데이트 안함
        IF OLD.status IS DISTINCT FROM NEW.status THEN
            RETURN NEW;
        END IF;
        
        -- 다른 컬럼이 변경된 경우에만 updated_at, updated_by 업데이트
        NEW.updated_at = NOW();
        NEW.updated_by = auth.uid();
        RETURN NEW;
    END IF;
    
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 기존 트리거 삭제 후 새 트리거 생성
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE INSERT OR UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_products_updated_at_column(); 