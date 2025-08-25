-- 보험코드별 업체 할당 테이블 생성
-- 2025-01-07

-- 0. 기존 정책 및 트리거 삭제 (이미 존재하는 경우)
DROP POLICY IF EXISTS "Admins can manage all insurance code assignments" ON product_insurance_code_company_assignments;
DROP TRIGGER IF EXISTS trigger_update_product_insurance_code_assignments_updated_at ON product_insurance_code_company_assignments;

-- 1. 시퀀스 생성
CREATE SEQUENCE IF NOT EXISTS product_insurance_code_company_assignments_id_seq;

-- 2. 테이블 생성
CREATE TABLE IF NOT EXISTS product_insurance_code_company_assignments (
    id bigint DEFAULT nextval('product_insurance_code_company_assignments_id_seq') PRIMARY KEY,
    insurance_code text NOT NULL,
    company_id uuid NOT NULL REFERENCES companies(id),
    is_active boolean DEFAULT true,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users(id),
    updated_by uuid REFERENCES auth.users(id),
    UNIQUE(insurance_code, company_id)
);

-- 3. 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_product_insurance_code_assignments_insurance_code ON product_insurance_code_company_assignments(insurance_code);
CREATE INDEX IF NOT EXISTS idx_product_insurance_code_assignments_company_id ON product_insurance_code_company_assignments(company_id);
CREATE INDEX IF NOT EXISTS idx_product_insurance_code_assignments_is_active ON product_insurance_code_company_assignments(is_active);

-- 4. RLS 정책 설정
ALTER TABLE product_insurance_code_company_assignments ENABLE ROW LEVEL SECURITY;

-- 관리자는 모든 보험코드 할당 관리 가능
CREATE POLICY "Admins can manage all insurance code assignments" ON product_insurance_code_company_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM companies 
            WHERE user_id = auth.uid() AND user_type = 'admin'
        )
    );

-- 5. updated_at 트리거 생성
CREATE OR REPLACE FUNCTION update_insurance_code_assignments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_product_insurance_code_assignments_updated_at
    BEFORE UPDATE ON product_insurance_code_company_assignments
    FOR EACH ROW
    EXECUTE FUNCTION update_insurance_code_assignments_updated_at();

-- 6. 권한 설정
GRANT ALL ON product_insurance_code_company_assignments TO authenticated;

-- 7. 기존 product_company_assignments 데이터를 보험코드별로 마이그레이션
INSERT INTO product_insurance_code_company_assignments (
    insurance_code, 
    company_id, 
    is_active, 
    created_by
)
SELECT DISTINCT
    p.insurance_code,
    pca.company_id,
    pca.is_active,
    pca.created_by
FROM product_company_assignments pca
JOIN products p ON pca.product_id = p.id
WHERE p.insurance_code IS NOT NULL 
  AND p.insurance_code != ''
  AND NOT EXISTS (
      SELECT 1 FROM product_insurance_code_company_assignments pica 
      WHERE pica.insurance_code = p.insurance_code 
        AND pica.company_id = pca.company_id
  ); 