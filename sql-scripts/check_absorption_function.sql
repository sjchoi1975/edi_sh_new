-- 현재 데이터베이스에 calculate_absorption_rates 함수가 존재하는지 확인

-- 1. 함수 존재 여부 확인
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname LIKE '%absorption%';

-- 2. RPC 함수 목록 확인 (Supabase에서 사용 가능한 함수들)
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%absorption%';

-- 3. 함수 상세 정보 확인
SELECT 
    p.proname as function_name,
    p.prosrc as function_source,
    p.prolang as language,
    p.prosecdef as security_definer
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'calculate_absorption_rates'; 