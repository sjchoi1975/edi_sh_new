-- admin_products_with_company_status 뷰의 status 컬럼 별칭 수정
-- 2025-01-07

-- 1. 기존 뷰 삭제
DROP VIEW IF EXISTS admin_products_with_company_status;

-- 2. admin_products_with_company_status 뷰 재생성 (status 컬럼 별칭 수정)
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
    p.base_month,
    p.status,  -- product_status에서 status로 변경
    p.created_at,
    p.updated_at,
    p.created_by,
    p.updated_by,
    -- 업체별 활성 상태 정보 (보험코드 기준)
    COALESCE(
        json_agg(
            json_build_object(
                'company_id', c.id,
                'company_name', c.company_name,
                'is_active', pica.is_active,
                'assignment_id', pica.id
            ) ORDER BY c.company_name
        ) FILTER (WHERE c.id IS NOT NULL),
        '[]'::json
    ) as company_assignments,
    -- 활성화된 업체 수 (보험코드 기준, 중복 제거)
    COUNT(DISTINCT pica.company_id) FILTER (WHERE pica.is_active = true) as active_companies_count,
    -- 전체 업체 수 (user 타입만)
    (SELECT COUNT(*) FROM companies WHERE status = 'active' AND user_type = 'user') as total_companies_count
FROM products p
LEFT JOIN product_insurance_code_company_assignments pica ON p.insurance_code = pica.insurance_code
LEFT JOIN companies c ON pica.company_id = c.id
WHERE p.status = 'active'
GROUP BY p.id, p.product_name, p.insurance_code, p.price,
         p.commission_rate_a, p.commission_rate_b, p.commission_rate_c,
         p.commission_rate_d, p.commission_rate_e, p.base_month, p.status,
         p.created_at, p.updated_at, p.created_by, p.updated_by;

-- 3. 권한 설정
GRANT SELECT ON admin_products_with_company_status TO authenticated; 