-- 흡수율 재분석 필요성 체크 함수
-- performance_records_absorption의 analysis_time 이후에 
-- performance_records에서 '완료' 상태로 변경된 건이 있는지 확인

CREATE OR REPLACE FUNCTION check_reanalysis_needed(p_settlement_month text)
RETURNS TABLE(
    needs_reanalysis boolean,
    last_analysis_time timestamptz,
    latest_completion_time timestamptz,
    records_after_analysis bigint
) AS $$
BEGIN
    RETURN QUERY
    WITH analysis_info AS (
        -- 해당 정산월의 가장 최근 analysis_time 조회
        SELECT 
            MAX(analysis_time) as last_analysis_time
        FROM performance_records_absorption 
        WHERE settlement_month = p_settlement_month
        AND analysis_time IS NOT NULL
    ),
    completion_info AS (
        -- analysis_time 이후에 완료된 건들 조회
        SELECT 
            MAX(pr.review_completed_at) as latest_completion_time,
            COUNT(*) as records_after_analysis
        FROM performance_records pr
        JOIN performance_records_absorption pra ON pr.id = pra.id
        JOIN analysis_info ai ON true
        WHERE pr.settlement_month = p_settlement_month
        AND pr.review_status = '완료'
        AND pr.review_completed_at IS NOT NULL
        AND (ai.last_analysis_time IS NULL OR pr.review_completed_at > ai.last_analysis_time)
    )
    SELECT 
        -- 재분석이 필요한지 여부
        CASE 
            WHEN ai.last_analysis_time IS NULL THEN true
            WHEN ci.latest_completion_time IS NULL THEN false
            WHEN ci.latest_completion_time > ai.last_analysis_time THEN true
            ELSE false
        END as needs_reanalysis,
        
        -- 마지막 분석 시간
        ai.last_analysis_time,
        
        -- 최근 완료 시간
        ci.latest_completion_time,
        
        -- 분석 이후 완료된 건 수
        COALESCE(ci.records_after_analysis, 0) as records_after_analysis
    FROM analysis_info ai
    LEFT JOIN completion_info ci ON true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 함수 설명 추가
COMMENT ON FUNCTION check_reanalysis_needed(text) IS '흡수율 재분석 필요성 체크. analysis_time 이후에 완료된 건이 있으면 true 반환';

-- 사용 예시 및 테스트
-- SELECT * FROM check_reanalysis_needed('2025-07');

-- 모든 정산월에 대한 재분석 필요성 체크
CREATE OR REPLACE VIEW reanalysis_status AS
SELECT 
    settlement_month,
    needs_reanalysis,
    last_analysis_time,
    latest_completion_time,
    records_after_analysis,
    CASE 
        WHEN needs_reanalysis THEN '재분석 필요'
        ELSE '재분석 불필요'
    END as status_description
FROM (
    SELECT DISTINCT settlement_month 
    FROM performance_records 
    WHERE settlement_month IS NOT NULL
) months
CROSS JOIN LATERAL check_reanalysis_needed(months.settlement_month);

-- 뷰 설명 추가
COMMENT ON VIEW reanalysis_status IS '각 정산월별 흡수율 재분석 상태를 보여주는 뷰';
