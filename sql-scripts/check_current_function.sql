-- 현재 데이터베이스에 있는 calculate_absorption_rates 함수 확인

-- 1. 함수 존재 여부 확인
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'calculate_absorption_rates';

-- 2. 함수의 실제 SQL 코드 확인
SELECT 
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'calculate_absorption_rates';

-- 3. wholesale_sales 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'wholesale_sales' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. direct_sales 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'direct_sales' 
AND table_schema = 'public'
ORDER BY ordinal_position; 