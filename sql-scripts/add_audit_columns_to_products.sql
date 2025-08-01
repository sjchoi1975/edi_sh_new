-- products 테이블에 감사 정보 컬럼 추가

-- 1. created_by 컬럼 추가 (이미 있다면 무시)
ALTER TABLE products ADD COLUMN IF NOT EXISTS created_by UUID;

-- 2. updated_by 컬럼 추가 (이미 있다면 무시)
ALTER TABLE products ADD COLUMN IF NOT EXISTS updated_by UUID;

-- 3. updated_at 컬럼 추가 (이미 있다면 무시)
ALTER TABLE products ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE;

-- 4. updated_at 자동 업데이트 트리거 함수 생성
CREATE OR REPLACE FUNCTION update_products_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.updated_by = auth.uid();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 5. UPDATE 전용 트리거 생성 (INSERT는 제외)
DROP TRIGGER IF EXISTS update_products_updated_at ON products;
CREATE TRIGGER update_products_updated_at
    BEFORE UPDATE ON products
    FOR EACH ROW
    EXECUTE FUNCTION update_products_updated_at_column(); 