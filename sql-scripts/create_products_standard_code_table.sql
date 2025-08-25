-- products_standard_code 테이블 생성
-- 2025-01-07

-- 1. 시퀀스 생성
CREATE SEQUENCE IF NOT EXISTS products_standard_code_id_seq;

-- 2. 테이블 생성
CREATE TABLE IF NOT EXISTS products_standard_code (
    id bigint DEFAULT nextval('products_standard_code_id_seq') PRIMARY KEY,
    insurance_code text NOT NULL,
    standard_code text NOT NULL,
    unit_packaging_desc text,
    unit_quantity integer,
    status text DEFAULT 'active',
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users(id),
    updated_by uuid REFERENCES auth.users(id),
    UNIQUE(insurance_code, standard_code)
);

-- 3. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_products_standard_code_insurance_code ON products_standard_code(insurance_code);
CREATE INDEX IF NOT EXISTS idx_products_standard_code_standard_code ON products_standard_code(standard_code);

-- 4. RLS 정책 설정
ALTER TABLE products_standard_code ENABLE ROW LEVEL SECURITY;

-- 관리자는 모든 표준코드 관리 가능
CREATE POLICY "Admins can manage all standard codes" ON products_standard_code
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM companies 
            WHERE user_id = auth.uid() AND user_type = 'admin'
        )
    );

-- 일반 사용자는 조회만 가능
CREATE POLICY "Users can view standard codes" ON products_standard_code
    FOR SELECT USING (true);

-- 5. updated_at 트리거 생성
CREATE OR REPLACE FUNCTION update_products_standard_code_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_products_standard_code_updated_at
    BEFORE UPDATE ON products_standard_code
    FOR EACH ROW
    EXECUTE FUNCTION update_products_standard_code_updated_at();

-- 6. 권한 설정
GRANT ALL ON products_standard_code TO authenticated; 