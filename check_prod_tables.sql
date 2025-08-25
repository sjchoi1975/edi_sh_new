-- 운영서버 테이블 구조 확인
-- 운영서버: vaeolqywqckiwwtspxfp

-- 1. public 스키마의 모든 테이블 목록
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;

-- 2. performance_records_absorption 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'performance_records_absorption'
ORDER BY ordinal_position;

-- 3. performance_records 테이블 구조 확인
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
  AND table_name = 'performance_records'
ORDER BY ordinal_position;

-- 4. 기존 뷰 확인
SELECT 
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public'
ORDER BY viewname;
