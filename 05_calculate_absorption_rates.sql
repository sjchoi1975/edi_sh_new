-- 기존 함수가 존재하면 삭제
DROP FUNCTION IF EXISTS public.calculate_absorption_rates(p_settlement_month text);

-- 새로운 함수 정의
CREATE OR REPLACE FUNCTION public.calculate_absorption_rates(p_settlement_month text)
RETURNS TABLE(
    analysis_id uuid, 
    wholesale_revenue numeric, 
    direct_revenue numeric
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- 1. 지정된 정산월에 해당하는 모든 '완료' 상태의 실적 데이터를 임시 테이블에 저장
    CREATE TEMP TABLE temp_performance_records AS
    SELECT *
    FROM public.v_review_details
    WHERE settlement_month = p_settlement_month
      AND review_status = '완료';

    -- 2. 제품의 보험코드와 표준코드를 매핑하는 임시 테이블 생성
    CREATE TEMP TABLE temp_product_codes AS
    SELECT DISTINCT insurance_code, standard_code
    FROM public.products
    WHERE standard_code IS NOT NULL;

    -- 3. 각 약국별, 제품별, 월별 매출(도매/직거래) 집계
    CREATE TEMP TABLE temp_pharmacy_sales AS
    SELECT 
        p.business_registration_number,
        pc.insurance_code,
        TO_CHAR(s.sales_date, 'YYYY-MM') AS sales_month,
        SUM(CASE WHEN s.sales_type = '도매' THEN s.sales_amount ELSE 0 END) AS monthly_wholesale,
        SUM(CASE WHEN s.sales_type = '직거래' THEN s.sales_amount ELSE 0 END) AS monthly_direct
    FROM public.sales_records s
    JOIN public.pharmacies p ON s.pharmacy_id = p.id
    JOIN temp_product_codes pc ON s.product_standard_code = pc.standard_code
    GROUP BY p.business_registration_number, pc.insurance_code, TO_CHAR(s.sales_date, 'YYYY-MM');

    -- 4. 각 병원(client)에 연결된 문전약국 목록 생성
    CREATE TEMP TABLE temp_client_pharmacy_map AS
    SELECT 
        cpm.client_id,
        p.business_registration_number AS pharmacy_brn
    FROM public.client_pharmacy_mappings cpm
    JOIN public.pharmacies p ON cpm.pharmacy_id = p.id;

    -- 5. 약국별로 연결된 병원 수 계산
    CREATE TEMP TABLE temp_pharmacy_hospital_count AS
    SELECT
        pharmacy_brn,
        COUNT(DISTINCT client_id) as hospital_count
    FROM temp_client_pharmacy_map
    GROUP BY pharmacy_brn;

    -- 6. 각 약국-제품-월별로 총 처방 수량 계산 (매출 분배 기준)
    CREATE TEMP TABLE temp_distribution_base AS
    SELECT
        cpm.pharmacy_brn,
        pr.insurance_code,
        pr.prescription_month,
        SUM(pr.prescription_qty) AS total_qty_for_distribution
    FROM temp_performance_records pr
    JOIN temp_client_pharmacy_map cpm ON pr.client_id = cpm.client_id
    GROUP BY cpm.pharmacy_brn, pr.insurance_code, pr.prescription_month;

    -- 7. 최종 결과 계산
    RETURN QUERY
    WITH final_revenues AS (
        SELECT 
            pr.id AS record_id,
            -- 도매 매출 계산
            SUM(
                COALESCE(ps.monthly_wholesale, 0) * 
                (CASE 
                    WHEN phc.hospital_count > 1 THEN (pr.prescription_qty::numeric / NULLIF(tdb.total_qty_for_distribution, 0))
                    ELSE 1 
                END)
            ) AS calculated_wholesale,
            -- 직거래 매출 계산
            SUM(
                COALESCE(ps.monthly_direct, 0) *
                (CASE 
                    WHEN phc.hospital_count > 1 THEN (pr.prescription_qty::numeric / NULLIF(tdb.total_qty_for_distribution, 0))
                    ELSE 1 
                END)
            ) AS calculated_direct
        FROM temp_performance_records pr
        -- 병원에 연결된 약국 정보 조인
        JOIN temp_client_pharmacy_map cpm ON pr.client_id = cpm.client_id
        -- 약국의 병원 연결 수 정보 조인
        JOIN temp_pharmacy_hospital_count phc ON cpm.pharmacy_brn = phc.pharmacy_brn
        -- 약국의 월별 매출 정보 조인
        LEFT JOIN temp_pharmacy_sales ps 
            ON cpm.pharmacy_brn = ps.business_registration_number
            AND pr.insurance_code = ps.insurance_code
            AND pr.prescription_month = ps.sales_month
        -- 매출 분배 기준(총 수량) 조인
        LEFT JOIN temp_distribution_base tdb
            ON cpm.pharmacy_brn = tdb.pharmacy_brn
            AND pr.insurance_code = tdb.insurance_code
            AND pr.prescription_month = tdb.prescription_month
        GROUP BY pr.id
    )
    SELECT 
        fr.record_id, 
        ROUND(fr.calculated_wholesale, 0)::numeric, 
        ROUND(fr.calculated_direct, 0)::numeric
    FROM final_revenues fr;

    -- 임시 테이블 삭제
    DROP TABLE temp_performance_records;
    DROP TABLE temp_product_codes;
    DROP TABLE temp_pharmacy_sales;
    DROP TABLE temp_client_pharmacy_map;
    DROP TABLE temp_pharmacy_hospital_count;
    DROP TABLE temp_distribution_base;

END;
$$; 