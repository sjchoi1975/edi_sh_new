-- 3단계: 함수 및 뷰 업데이트
-- 개발서버 → 운영서버 동기화
-- 운영서버: vaeolqywqckiwwtspxfp

-- =====================================================
-- 1. 흡수율 분석 함수 업데이트
-- =====================================================

-- 기존 함수 삭제
DROP FUNCTION IF EXISTS public.calculate_absorption_rates(text);

-- 새로운 함수 생성 (최신 버전)
CREATE OR REPLACE FUNCTION public.calculate_absorption_rates(p_settlement_month text)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    result_record RECORD;
BEGIN
    -- 1단계: 기존 흡수율 데이터 초기화
    UPDATE performance_records_absorption 
    SET 
        wholesale_revenue = 0,
        direct_revenue = 0,
        total_revenue = 0,
        absorption_rate = 0
    WHERE settlement_month = p_settlement_month;
    
    -- 2단계: 흡수율 계산 및 업데이트
    FOR result_record IN
        WITH 
        -- 1. 선택된 정산월에 해당하는 모든 실적 데이터를 performance_records_absorption에서 가져옴
        performance_base AS (
            SELECT 
                pra.id as absorption_analysis_id,
                pra.client_id,
                pra.product_id,
                p.insurance_code,
                psc.standard_code, -- 도매/직거래 매출 매칭을 위한 표준코드
                pra.prescription_month,
                pra.prescription_qty,
                -- 처방액 계산: 수량 * 제품 가격
                (pra.prescription_qty * p.price) as prescription_amount
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
        -- 3. 약국별로 연결된 병원 수 계산 (pharmacy_id를 id로 별칭)
        pharmacy_hospital_count AS (
            SELECT pharmacy_id as id, COUNT(client_id) AS hospital_count
            FROM client_pharmacy_map
            GROUP BY pharmacy_id
        ),
        -- 4. 약국-제품-월별 총 처방수량 계산
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
            pb.absorption_analysis_id,
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
            ) AS direct_revenue,
            -- 처방액 (흡수율 계산용)
            pb.prescription_amount
        FROM performance_base pb
        -- 병원에 연결된 약국 정보 조인
        JOIN client_pharmacy_map cpm ON pb.client_id = cpm.client_id
        -- 약국의 병원 연결 수 정보 조인 (phc.id로 참조 가능)
        JOIN pharmacy_hospital_count phc ON cpm.pharmacy_id = phc.id
        -- 도매 매출 정보 조인 (올바른 컬럼명 사용)
        LEFT JOIN wholesale_sales ws 
            ON cpm.pharmacy_brn = ws.business_registration_number
            AND pb.standard_code = ws.standard_code
            AND pb.prescription_month = TO_CHAR(ws.sales_date, 'YYYY-MM')
        -- 직거래 매출 정보 조인 (올바른 컬럼명 사용)
        LEFT JOIN direct_sales ds 
            ON cpm.pharmacy_brn = ds.business_registration_number
            AND pb.standard_code = ds.standard_code
            AND pb.prescription_month = TO_CHAR(ds.sales_date, 'YYYY-MM')
        -- 약국-제품-월별 총 처방수량 정보 조인
        LEFT JOIN distribution_base tdb 
            ON cpm.pharmacy_brn = tdb.pharmacy_brn
            AND pb.standard_code = tdb.standard_code
            AND pb.prescription_month = tdb.prescription_month
        GROUP BY pb.absorption_analysis_id, pb.prescription_amount
    LOOP
        -- 3단계: 흡수율 데이터 업데이트
        UPDATE performance_records_absorption 
        SET 
            wholesale_revenue = result_record.wholesale_revenue,
            direct_revenue = result_record.direct_revenue,
            total_revenue = result_record.wholesale_revenue + result_record.direct_revenue,
            absorption_rate = CASE 
                WHEN result_record.prescription_amount > 0 THEN 
                    ((result_record.wholesale_revenue + result_record.direct_revenue) / result_record.prescription_amount) * 100
                ELSE 0 
            END,
            analysis_time = NOW()
        WHERE id = result_record.absorption_analysis_id;
    END LOOP;
END;
$$;

-- =====================================================
-- 2. 사용하지 않는 review_details_view 제거 (개발서버에도 없음)
-- =====================================================

-- 기존 뷰가 있다면 삭제
DROP VIEW IF EXISTS public.review_details_view;

-- =====================================================
-- 3. 누락된 인덱스 추가
-- =====================================================

-- performance_records_absorption 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_records_absorption_analysis_time 
ON public.performance_records_absorption USING btree (analysis_time);

-- performance_records 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_performance_records_review_completed_at 
ON public.performance_records USING btree (review_completed_at);

-- companies 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_companies_approval_status 
ON public.companies USING btree (approval_status);

CREATE INDEX IF NOT EXISTS idx_companies_business_registration_number 
ON public.companies USING btree (business_registration_number);

-- clients 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_clients_business_registration_number 
ON public.clients USING btree (business_registration_number);

CREATE INDEX IF NOT EXISTS idx_clients_status 
ON public.clients USING btree (status);

-- products 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_products_base_month 
ON public.products USING btree (base_month);

CREATE INDEX IF NOT EXISTS idx_products_insurance_code 
ON public.products USING btree (insurance_code);

-- products_standard_code 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_products_standard_code_standard_code 
ON public.products_standard_code USING btree (standard_code);

-- wholesale_sales 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_wholesale_sales_business_registration_number 
ON public.wholesale_sales USING btree (business_registration_number);

CREATE INDEX IF NOT EXISTS idx_wholesale_sales_standard_code 
ON public.wholesale_sales USING btree (standard_code);

-- direct_sales 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_direct_sales_business_registration_number 
ON public.direct_sales USING btree (business_registration_number);

CREATE INDEX IF NOT EXISTS idx_direct_sales_standard_code 
ON public.direct_sales USING btree (standard_code);

-- user_preferences 테이블 인덱스
CREATE INDEX IF NOT EXISTS idx_user_preferences_key 
ON public.user_preferences USING btree (preference_key);

CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id 
ON public.user_preferences USING btree (user_id);

-- =====================================================
-- 4. 동기화 완료 확인
-- =====================================================

-- 함수 존재 확인
SELECT 
    'calculate_absorption_rates function' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_proc p 
            JOIN pg_namespace n ON p.pronamespace = n.oid 
            WHERE n.nspname = 'public' AND p.proname = 'calculate_absorption_rates'
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;

-- 뷰 제거 확인
SELECT 
    'review_details_view removed' as check_item,
    CASE 
        WHEN NOT EXISTS (
            SELECT 1 FROM pg_views 
            WHERE schemaname = 'public' AND viewname = 'review_details_view'
        ) THEN 'REMOVED' 
        ELSE 'STILL EXISTS' 
    END as status;

-- 인덱스 존재 확인
SELECT 
    'performance_records_absorption_analysis_time index' as check_item,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_indexes 
            WHERE schemaname = 'public' 
            AND tablename = 'performance_records_absorption' 
            AND indexname = 'idx_performance_records_absorption_analysis_time'
        ) THEN 'EXISTS' 
        ELSE 'MISSING' 
    END as status;
