-- 개발서버용 스토리지 버킷 및 정책 설정 가이드

-- 1. 스토리지 버킷 생성 (Supabase 콘솔에서 수동 설정 필요)
-- Storage → New bucket → "notices" 생성 (Public 체크)
-- Storage → New bucket → "performance-evidence" 생성 (Public 체크 해제)

-- 2. 스토리지 정책 설정 (Supabase 콘솔에서 수동 설정 필요)

-- notices 버킷 정책:
-- INSERT: (bucket_id = 'notices'::text) AND (auth.role() = 'authenticated'::text)
-- SELECT: (bucket_id = 'notices'::text) AND (auth.role() = 'authenticated'::text)

-- performance-evidence 버킷 정책:
-- INSERT: (bucket_id = 'performance-evidence'::text) AND (auth.role() = 'authenticated'::text)
-- SELECT: (bucket_id = 'performance-evidence'::text) AND (auth.role() = 'authenticated'::text)
-- DELETE: (bucket_id = 'performance-evidence'::text) AND (auth.role() = 'authenticated'::text)

-- 3. notice_views 테이블 생성 (아래 SQL 실행)
CREATE TABLE IF NOT EXISTS notice_views (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    notice_id UUID NOT NULL REFERENCES notices(id) ON DELETE CASCADE,
    user_id UUID NOT NULL,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(notice_id, user_id)
);

-- 인덱스 추가 (성능 향상)
CREATE INDEX IF NOT EXISTS idx_notice_views_notice_id ON notice_views(notice_id);
CREATE INDEX IF NOT EXISTS idx_notice_views_user_id ON notice_views(user_id);
CREATE INDEX IF NOT EXISTS idx_notice_views_unique ON notice_views(notice_id, user_id); 