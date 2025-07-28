-- 사용자 매핑 문제 디버깅

-- 1. profiles 테이블 구조 확인
SELECT 
    'Profiles Table Structure' as info,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'profiles'
ORDER BY column_name;

-- 2. profiles 테이블 샘플 데이터 확인
SELECT 
    'Sample Profiles Data' as info,
    id,
    company_name,
    email,
    created_at
FROM profiles 
LIMIT 5;

-- 3. performance_records_absorption 테이블의 registered_by, updated_by 확인
SELECT 
    'Absorption Records User IDs' as info,
    registered_by,
    updated_by,
    COUNT(*) as count
FROM performance_records_absorption 
WHERE registered_by IS NOT NULL OR updated_by IS NOT NULL
GROUP BY registered_by, updated_by
ORDER BY count DESC
LIMIT 10;

-- 4. 실제 매핑 테스트
WITH user_ids AS (
    SELECT DISTINCT registered_by as user_id
    FROM performance_records_absorption 
    WHERE registered_by IS NOT NULL
    UNION
    SELECT DISTINCT updated_by as user_id
    FROM performance_records_absorption 
    WHERE updated_by IS NOT NULL
)
SELECT 
    'User Mapping Test' as info,
    ui.user_id,
    p.company_name,
    p.email,
    CASE 
        WHEN p.id IS NOT NULL THEN 'Found in profiles'
        ELSE 'Not found in profiles'
    END as status
FROM user_ids ui
LEFT JOIN profiles p ON ui.user_id = p.id
ORDER BY p.company_name; 