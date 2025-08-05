-- 제품 조회 로직을 업체별 활성/비활성 고려하도록 수정
-- 2025-01-07

-- 1. 관리자용 제품 조회 뷰 생성 (모든 제품 + 업체별 활성 상태)
-- 기존 뷰 삭제 후 재생성
DROP VIEW IF EXISTS admin_products_with_company_status;
CREATE VIEW admin_products_with_company_status AS
SELECT 
    p.id,
    p.product_name,
    p.insurance_code,
    p.price,
    p.commission_rate_a,
    p.commission_rate_b,
    p.commission_rate_c,
    p.commission_rate_d,
    p.commission_rate_e,
    p.standard_code,
    p.unit_packaging_desc,
    p.unit_quantity,
    p.base_month,
    p.status as product_status,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by,
    -- 업체별 활성 상태 정보
    COALESCE(
        json_agg(
            json_build_object(
                'company_id', c.id,
                'company_name', c.company_name,
                'is_active', pca.is_active,
                'assignment_id', pca.id
            ) ORDER BY c.company_name
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'::json
    ) as company_assignments,
    -- 활성화된 업체 수
    COUNT(pca.id) FILTER (WHERE pca.is_active = true) as active_companies_count,
    -- 전체 업체 수 (user 타입만)
    (SELECT COUNT(*) FROM companies WHERE status = 'active' AND user_type = 'user') as total_companies_count
FROM products p
LEFT JOIN product_company_assignments pca ON p.id = pca.product_id
LEFT JOIN companies c ON pca.company_id = c.id
WHERE p.status = 'active'
GROUP BY p.id, p.product_name, p.insurance_code, p.price, 
         p.commission_rate_a, p.commission_rate_b, p.commission_rate_c,
         p.commission_rate_d, p.commission_rate_e, p.standard_code,
         p.unit_packaging_desc, p.unit_quantity, p.base_month, p.status,
         p.created_at, p.updated_at, p.created_by, p.updated_by;

-- 2. 사용자용 제품 조회 뷰 생성 (자신의 업체에 활성화된 제품만)
-- 기존 뷰 삭제 후 재생성
DROP VIEW IF EXISTS user_products;
CREATE VIEW user_products AS
SELECT DISTINCT
    p.id,
    p.product_name,
    p.insurance_code,
    p.price,
    p.commission_rate_a,
    p.commission_rate_b,
    p.commission_rate_c,
    p.commission_rate_d,
    p.commission_rate_e,
    p.standard_code,
    p.unit_packaging_desc,
    p.unit_quantity,
    p.base_month,
    p.status,
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by
FROM products p
INNER JOIN product_company_assignments pca ON p.id = pca.product_id
INNER JOIN companies c ON pca.company_id = c.id
WHERE p.status = 'active'
  AND pca.is_active = true
  AND c.user_id = auth.uid();

-- 3. 제품별 업체 할당 현황 조회 함수
-- 기존 함수 삭제 후 재생성 (반환 타입 변경 때문)
DROP FUNCTION IF EXISTS get_product_company_assignments(uuid);
CREATE FUNCTION get_product_company_assignments(product_uuid uuid)
RETURNS TABLE (
    company_id uuid,
    company_name text,
    business_number text,
    representative text,
    business_location text,
    is_active boolean,
    assignment_id bigint
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id as company_id,
        c.company_name,
        c.business_registration_number as business_number,
        c.representative_name as representative,
        c.business_address as business_location,
        COALESCE(pca.is_active, false) as is_active,
        pca.id as assignment_id
               FROM companies c
           LEFT JOIN product_company_assignments pca ON c.id = pca.company_id AND pca.product_id = product_uuid
           WHERE c.status = 'active' AND c.user_type = 'user'
           ORDER BY c.company_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. 제품-업체 할당 일괄 업데이트 함수
CREATE OR REPLACE FUNCTION update_product_company_assignments(
    p_product_id uuid,
    p_assignments json
)
RETURNS void AS $$
DECLARE
    assignment json;
    v_company_id text;
    v_is_active text;
BEGIN
    -- 기존 할당 삭제
    DELETE FROM product_company_assignments 
    WHERE product_id = p_product_id;
    
    -- 새로운 할당 추가
    FOR assignment IN SELECT * FROM json_array_elements(p_assignments)
    LOOP
        v_company_id := assignment::text;
        v_is_active := assignment::text;
        
        -- JSON에서 값 추출 (문자열 파싱 방식)
        v_company_id := substring(v_company_id from '"company_id":"([^"]+)"');
        v_is_active := substring(v_is_active from '"is_active":([^,}]+)');
        
        INSERT INTO product_company_assignments (
            product_id, 
            company_id, 
            is_active, 
            created_by
        ) VALUES (
            p_product_id,
            v_company_id::uuid,
            CASE WHEN v_is_active = 'true' THEN true ELSE false END,
            auth.uid()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. 뷰 권한 설정
GRANT SELECT ON admin_products_with_company_status TO authenticated;
GRANT SELECT ON user_products TO authenticated;

-- 6. 함수 권한 설정
GRANT EXECUTE ON FUNCTION get_product_company_assignments(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_product_company_assignments(uuid, json) TO authenticated;

-- 7. 테스트 데이터 삽입 (기존 제품들을 모든 업체에 활성화)
INSERT INTO product_company_assignments (product_id, company_id, is_active, created_by)
SELECT 
    p.id as product_id,
    c.id as company_id,
    true as is_active,
    (SELECT id FROM auth.users WHERE email = 'admin@shinil.com' LIMIT 1) as created_by
FROM products p
CROSS JOIN companies c
WHERE p.status = 'active' 
  AND c.status = 'active'
  AND NOT EXISTS (
      SELECT 1 FROM product_company_assignments pca 
      WHERE pca.product_id = p.id AND pca.company_id = c.id
  );

-- 8. 생성된 뷰 확인
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name IN ('admin_products_with_company_status', 'user_products')
AND table_schema = 'public';

-- 9. 샘플 데이터 확인
SELECT 
    product_name,
    active_companies_count,
    total_companies_count,
    company_assignments
FROM admin_products_with_company_status 
LIMIT 3; 