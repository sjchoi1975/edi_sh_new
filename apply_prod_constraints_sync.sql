-- 운영서버 제약조건 동기화 스크립트
-- 운영서버: vaeolqywqckiwwtspxfp
-- 목적: 개발서버와 동일한 제약조건 상태로 동기화

-- =====================================================
-- 1. performance_records_absorption 테이블 제약조건
-- =====================================================

-- 1-1. Primary Key 제거 (개발서버와 동일하게 0개로 맞춤)
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_pkey;

-- 1-2. 체크 제약조건 추가 (9개)
-- commission_rate 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_commission_rate_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_commission_rate_check 
CHECK (commission_rate >= 0 AND commission_rate <= 100);

-- prescription_qty 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_prescription_qty_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_prescription_qty_check 
CHECK (prescription_qty >= 0);

-- absorption_rate 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_absorption_rate_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_absorption_rate_check 
CHECK (absorption_rate >= 0 AND absorption_rate <= 100);

-- analysis_amount 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_analysis_amount_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_analysis_amount_check 
CHECK (analysis_amount >= 0);

-- analysis_commission_amount 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_analysis_commission_amount_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_analysis_commission_amount_check 
CHECK (analysis_commission_amount >= 0);

-- analysis_absorption_amount 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_analysis_absorption_amount_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_analysis_absorption_amount_check 
CHECK (analysis_absorption_amount >= 0);

-- analysis_absorption_commission_amount 범위 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_analysis_absorption_commission_amount_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_analysis_absorption_commission_amount_check 
CHECK (analysis_absorption_commission_amount >= 0);

-- review_status 값 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_review_status_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_review_status_check 
CHECK (review_status IN ('대기', '검수중', '완료', '반려'));

-- review_action 값 체크
ALTER TABLE performance_records_absorption DROP CONSTRAINT IF EXISTS performance_records_absorption_review_action_check;
ALTER TABLE performance_records_absorption ADD CONSTRAINT performance_records_absorption_review_action_check 
CHECK (review_action IN ('승인', '반려', '수정요청'));

-- =====================================================
-- 2. product_company_not_assignments 테이블 제약조건
-- =====================================================

-- 2-1. 외래키 제약조건 추가 (4개)
-- product_id → products.id
ALTER TABLE product_company_not_assignments DROP CONSTRAINT IF EXISTS product_company_not_assignments_product_id_fkey;
ALTER TABLE product_company_not_assignments ADD CONSTRAINT product_company_not_assignments_product_id_fkey 
FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- company_id → companies.id
ALTER TABLE product_company_not_assignments DROP CONSTRAINT IF EXISTS product_company_not_assignments_company_id_fkey;
ALTER TABLE product_company_not_assignments ADD CONSTRAINT product_company_not_assignments_company_id_fkey 
FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- created_by → auth.users(id)
ALTER TABLE product_company_not_assignments DROP CONSTRAINT IF EXISTS product_company_not_assignments_created_by_fkey;
ALTER TABLE product_company_not_assignments ADD CONSTRAINT product_company_not_assignments_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- updated_by → auth.users(id)
ALTER TABLE product_company_not_assignments DROP CONSTRAINT IF EXISTS product_company_not_assignments_updated_by_fkey;
ALTER TABLE product_company_not_assignments ADD CONSTRAINT product_company_not_assignments_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- 2-2. 유니크 제약조건 추가 (1개)
-- product_id + company_id 복합 유니크
ALTER TABLE product_company_not_assignments DROP CONSTRAINT IF EXISTS product_company_not_assignments_product_company_unique;
ALTER TABLE product_company_not_assignments ADD CONSTRAINT product_company_not_assignments_product_company_unique 
UNIQUE (product_id, company_id);

-- =====================================================
-- 3. products_standard_code 테이블 제약조건
-- =====================================================

-- 3-1. 외래키 제약조건 추가 (2개)
-- created_by → auth.users(id)
ALTER TABLE products_standard_code DROP CONSTRAINT IF EXISTS products_standard_code_created_by_fkey;
ALTER TABLE products_standard_code ADD CONSTRAINT products_standard_code_created_by_fkey 
FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- updated_by → auth.users(id)
ALTER TABLE products_standard_code DROP CONSTRAINT IF EXISTS products_standard_code_updated_by_fkey;
ALTER TABLE products_standard_code ADD CONSTRAINT products_standard_code_updated_by_fkey 
FOREIGN KEY (updated_by) REFERENCES auth.users(id) ON DELETE SET NULL ON UPDATE CASCADE;

-- =====================================================
-- 4. user_preferences 테이블 제약조건
-- =====================================================

-- 4-1. 외래키 제약조건 추가 (2개)
-- user_id → auth.users(id)
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_user_id_fkey;
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- settlement_month_id → settlement_months(id)
ALTER TABLE user_preferences DROP CONSTRAINT IF EXISTS user_preferences_settlement_month_id_fkey;
ALTER TABLE user_preferences ADD CONSTRAINT user_preferences_settlement_month_id_fkey 
FOREIGN KEY (settlement_month_id) REFERENCES settlement_months(id) ON DELETE CASCADE ON UPDATE CASCADE;

-- =====================================================
-- 5. 제약조건 적용 확인
-- =====================================================

-- 5-1. 전체 제약조건 요약 재확인
SELECT 
    'Updated Constraints Summary' as info,
    tc.table_name,
    COUNT(CASE WHEN tc.constraint_type = 'FOREIGN KEY' THEN 1 END) as foreign_keys,
    COUNT(CASE WHEN tc.constraint_type = 'UNIQUE' THEN 1 END) as unique_constraints,
    COUNT(CASE WHEN tc.constraint_type = 'CHECK' THEN 1 END) as check_constraints,
    COUNT(CASE WHEN tc.constraint_type = 'PRIMARY KEY' THEN 1 END) as primary_keys
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'public'
    AND tc.table_name IN (
        'performance_records_absorption',
        'product_company_not_assignments',
        'products_standard_code',
        'user_preferences'
    )
GROUP BY tc.table_name
ORDER BY tc.table_name;
