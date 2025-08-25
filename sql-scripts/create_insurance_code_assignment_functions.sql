-- 보험코드별 업체 할당 함수들
-- 2025-01-07

-- 1. 보험코드별 업체 할당 현황 조회 함수
DROP FUNCTION IF EXISTS get_insurance_code_company_assignments(text);
CREATE FUNCTION get_insurance_code_company_assignments(insurance_code_param text)
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
        COALESCE(pica.is_active, false) as is_active,
        pica.id as assignment_id
    FROM companies c
    LEFT JOIN product_insurance_code_company_assignments pica ON c.id = pica.company_id AND pica.insurance_code = insurance_code_param
    WHERE c.status = 'active' AND c.user_type = 'user'
    ORDER BY c.company_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. 보험코드별 업체 할당 일괄 업데이트 함수
DROP FUNCTION IF EXISTS update_insurance_code_company_assignments(text, json);
CREATE FUNCTION update_insurance_code_company_assignments(
    p_insurance_code text,
    p_assignments json
)
RETURNS void AS $$
DECLARE
    assignment json;
    v_company_id text;
    v_is_active text;
BEGIN
    -- 기존 할당 삭제
    DELETE FROM product_insurance_code_company_assignments 
    WHERE insurance_code = p_insurance_code;
    
    -- 새로운 할당 추가
    FOR assignment IN SELECT * FROM json_array_elements(p_assignments)
    LOOP
        v_company_id := assignment::text;
        v_is_active := assignment::text;
        
        -- JSON에서 값 추출 (문자열 파싱 방식)
        v_company_id := substring(v_company_id from '"company_id":"([^"]+)"');
        v_is_active := substring(v_is_active from '"is_active":([^,}]+)');
        
        INSERT INTO product_insurance_code_company_assignments (
            insurance_code, 
            company_id, 
            is_active, 
            created_by
        ) VALUES (
            p_insurance_code,
            v_company_id::uuid,
            CASE WHEN v_is_active = 'true' THEN true ELSE false END,
            auth.uid()
        );
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 함수 권한 설정
GRANT EXECUTE ON FUNCTION get_insurance_code_company_assignments(text) TO authenticated;
GRANT EXECUTE ON FUNCTION update_insurance_code_company_assignments(text, json) TO authenticated; 