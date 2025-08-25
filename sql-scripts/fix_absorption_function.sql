-- calculate_absorption_rates 함수를 Supabase RPC로 사용할 수 있도록 수정
-- 기존 함수 삭제 후 다시 생성

-- 1. 기존 함수 삭제
DROP FUNCTION IF EXISTS public.calculate_absorption_rates(p_settlement_month text);

-- 2. 새로운 함수 생성 (Supabase RPC 호환)
CREATE OR REPLACE FUNCTION public.calculate_absorption_rates(p_settlement_month text)
RETURNS TABLE(
    analysis_id bigint, 
    wholesale_revenue numeric, 
    direct_revenue numeric
)
LANGUAGE plpgsql
SECURITY DEFINER -- Supabase RPC 호환을 위해 추가
AS $$
BEGIN
    RETURN QUERY
    WITH 
    -- 1. 선택된 정산월에 해당하는 '완료' 상태의 모든 실적 데이터를 performance_records_absorption에서 가져옴
    performance_base AS (
        SELECT 
            pra.id as absorption_analysis_id,
            pra.client_id,
            pra.product_id,
            p.insurance_code,
            psc.standard_code, -- 도매/직거래 매출 매칭을 위한 표준코드 (products_standard_code 테이블에서 가져옴)
            pra.prescription_month,
            pra.prescription_qty
        FROM public.performance_records_absorption pra
        JOIN products p ON pra.product_id = p.id
        LEFT JOIN products_standard_code psc ON p.insurance_code = psc.insurance_code
        WHERE pra.settlement_month = p_settlement_month
    ),
    -- 2. 병원-약국 매핑 정보
    client_pharmacy_map AS (
        SELECT cpa.client_id, cpa.pharmacy_id, p.business_registration_number AS pharmacy_brn
        FROM client_pharmacy_assignments cpa
        JOIN pharmacies p ON cpa.pharmacy_id = p.id
    ),
    -- 3. 약국별로 연결된 병원 수 계산 (매출 분배 로직에 사용)
    pharmacy_hospital_count AS (
        SELECT pharmacy_id, COUNT(client_id) AS hospital_count
        FROM client_pharmacy_map
        GROUP BY pharmacy_id
    ),
    -- 4. 약국-제품-월별 총 처방수량 계산 (매출 분배 기준)
    distribution_base AS (
        SELECT
            cpm.pharmacy_brn,
            pb.standard_code,
            pb.prescription_month,
            SUM(pb.prescription_qty) AS total_qty_for_distribution
        FROM performance_base pb
        JOIN client_pharmacy_map cpm ON pb.client_id = cpm.client_id
        WHERE pb.standard_code IS NOT NULL
        GROUP BY cpm.pharmacy_brn, pb.standard_code, pb.prescription_month
    )
    -- 5. 최종 결과 계산
    SELECT 
        pb.absorption_analysis_id AS analysis_id,
        -- 도매 매출 계산
        SUM(
            COALESCE(ws.sales_amount, 0) * 
            (CASE 
                WHEN phc.hospital_count > 1 THEN (pb.prescription_qty::numeric / NULLIF(tdb.total_qty_for_distribution, 0))
                ELSE 1 
            END)
        ) AS wholesale_revenue,
        -- 직거래 매출 계산
        SUM(
            COALESCE(ds.sales_amount, 0) *
            (CASE 
                WHEN phc.hospital_count > 1 THEN (pb.prescription_qty::numeric / NULLIF(tdb.total_qty_for_distribution, 0))
                ELSE 1 
            END)
        ) AS direct_revenue
    FROM performance_base pb
    -- 병원에 연결된 약국 정보 조인
    JOIN client_pharmacy_map cpm ON pb.client_id = cpm.client_id
    -- 약국의 병원 연결 수 정보 조인
    JOIN pharmacy_hospital_count phc ON cpm.pharmacy_id = phc.id
    -- 도매 매출 정보 조인
    LEFT JOIN wholesale_sales ws 
        ON cpm.pharmacy_brn = ws.business_registration_number
        AND pb.standard_code = ws.product_code
        AND pb.prescription_month = ws.sales_month
    -- 직거래 매출 정보 조인
    LEFT JOIN direct_sales ds 
        ON cpm.pharmacy_brn = ds.business_registration_number
        AND pb.standard_code = ds.product_code
        AND pb.prescription_month = ds.sales_month
    -- 매출 분배 기준(총 수량) 조인
    LEFT JOIN distribution_base tdb
        ON cpm.pharmacy_brn = tdb.pharmacy_brn
        AND pb.standard_code = tdb.standard_code
        AND pb.prescription_month = tdb.prescription_month
    GROUP BY pb.absorption_analysis_id;
END;
$$;

-- 3. 함수 권한 설정 (Supabase RPC 호환)
GRANT EXECUTE ON FUNCTION public.calculate_absorption_rates(text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.calculate_absorption_rates(text) TO anon;

-- 4. 함수가 제대로 생성되었는지 확인
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'calculate_absorption_rates'; 