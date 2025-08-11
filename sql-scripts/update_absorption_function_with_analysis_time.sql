-- 흡수율 분석 함수 (analysis_time은 프론트엔드에서 설정됨)
-- 기존 calculate_absorption_rates 함수를 수정하여 흡수율만 계산

CREATE OR REPLACE FUNCTION calculate_absorption_rates(p_settlement_month text)
RETURNS TABLE(
    id bigint,
    wholesale_revenue numeric,
    direct_revenue numeric,
    total_revenue numeric,
    absorption_rate numeric
) AS $$
BEGIN
    -- 흡수율 계산 (기존 로직)
    RETURN QUERY
    WITH absorption_calc AS (
        SELECT 
            pra.id,
            COALESCE(SUM(ws.revenue), 0) as wholesale_revenue,
            COALESCE(SUM(ds.revenue), 0) as direct_revenue,
            COALESCE(SUM(ws.revenue), 0) + COALESCE(SUM(ds.revenue), 0) as total_revenue,
            CASE 
                WHEN pra.prescription_qty * p.price > 0 THEN 
                    ((COALESCE(SUM(ws.revenue), 0) + COALESCE(SUM(ds.revenue), 0)) / (pra.prescription_qty * p.price)) * 100
                ELSE 0 
            END as absorption_rate
        FROM performance_records_absorption pra
        LEFT JOIN products p ON pra.product_id = p.id
        LEFT JOIN wholesale_sales ws ON 
            ws.client_id = pra.client_id 
            AND ws.product_id = pra.product_id 
            AND ws.sales_month = pra.prescription_month
        LEFT JOIN direct_sales ds ON 
            ds.client_id = pra.client_id 
            AND ds.product_id = pra.product_id 
            AND ds.sales_month = pra.prescription_month
        WHERE pra.settlement_month = p_settlement_month
        AND pra.review_status = '완료'
        GROUP BY pra.id, pra.prescription_qty, p.price
    )
    SELECT 
        ac.id,
        ac.wholesale_revenue,
        ac.direct_revenue,
        ac.total_revenue,
        ac.absorption_rate
    FROM absorption_calc ac;

END;
$$ LANGUAGE plpgsql;

-- 함수 설명 업데이트
COMMENT ON FUNCTION calculate_absorption_rates(text) IS '흡수율을 계산하는 함수. analysis_time은 프론트엔드에서 데이터 복사 시점에 설정됨.';
