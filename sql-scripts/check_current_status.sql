-- 현재 데이터베이스 상태 확인
-- 2025-01-07

-- 1. 기존 테이블 확인
SELECT '=== 기존 테이블 확인 ===' as status;
SELECT table_name, table_type 
FROM information_schema.tables 
WHERE table_name LIKE '%insurance_code%' 
   OR table_name LIKE '%product_company%'
ORDER BY table_name;

-- 2. 기존 함수 확인
SELECT '=== 기존 함수 확인 ===' as status;
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_name LIKE '%insurance_code%'
   OR routine_name LIKE '%product_company%'
ORDER BY routine_name;

-- 3. 기존 뷰 확인
SELECT '=== 기존 뷰 확인 ===' as status;
SELECT table_name 
FROM information_schema.views 
WHERE table_name LIKE '%products%'
ORDER BY table_name;

-- 4. 기존 정책 확인
SELECT '=== 기존 정책 확인 ===' as status;
SELECT schemaname, tablename, policyname
FROM pg_policies 
WHERE tablename LIKE '%insurance_code%'
   OR tablename LIKE '%product_company%'
ORDER BY tablename, policyname;

-- 5. 기존 트리거 확인
SELECT '=== 기존 트리거 확인 ===' as status;
SELECT trigger_name, event_object_table
FROM information_schema.triggers
WHERE event_object_table LIKE '%insurance_code%'
   OR event_object_table LIKE '%product_company%'
ORDER BY event_object_table, trigger_name; 