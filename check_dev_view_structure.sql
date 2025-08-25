-- 개발서버 review_details_view 구조 확인
-- 개발서버: selklngerzfmuvagcvvf

-- 1. review_details_view가 참조하는 테이블들 확인
SELECT 
    viewname,
    definition
FROM pg_views
WHERE schemaname = 'public' 
  AND viewname = 'review_details_view';

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

-- 4. public 스키마의 모든 테이블 목록
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_type = 'BASE TABLE'
ORDER BY table_name;
