-- 제품-업체 할당 함수 수정
-- 2025-01-07

-- 1. 기존 함수 완전 삭제
DROP FUNCTION IF EXISTS get_product_company_assignments(uuid);
DROP FUNCTION IF EXISTS update_product_company_assignments(uuid, json);

-- 2. 제품별 업체 할당 현황 조회 함수 (올바른 컬럼명 사용)
CREATE FUNCTION get_product_company_assignments(product_uuid uuid)
RETURNS TABLE (
    company_id uuid,
    company_name text,
    business_number text,
    representative text,
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
        COALESCE(pca.is_active, false) as is_active,
        pca.id as assignment_id
    FROM companies c
    LEFT JOIN product_company_assignments pca ON c.id = pca.company_id AND pca.product_id = product_uuid
    WHERE c.status = 'active'
    ORDER BY c.company_name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. 제품-업체 할당 일괄 업데이트 함수
CREATE FUNCTION update_product_company_assignments(
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

-- 4. 함수 권한 설정
GRANT EXECUTE ON FUNCTION get_product_company_assignments(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION update_product_company_assignments(uuid, json) TO authenticated;

-- 5. 함수 테스트
SELECT 'Function created successfully' as status;

-- 6. 샘플 데이터 확인 (선택사항)
-- SELECT * FROM get_product_company_assignments('제품ID') LIMIT 5; 