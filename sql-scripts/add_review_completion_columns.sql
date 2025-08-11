-- performance_records 테이블에 검수 완료 시간과 완료자 컬럼 추가
-- 흡수율 재분석 체크를 위한 정확한 완료 시점 추적

-- 1. 컬럼 추가
ALTER TABLE performance_records 
ADD COLUMN review_completed_at timestamptz,
ADD COLUMN review_completed_by uuid REFERENCES auth.users(id);

-- 2. 인덱스 추가 (조회 성능 향상)
CREATE INDEX idx_performance_records_review_completed_at 
ON performance_records(review_completed_at);

CREATE INDEX idx_performance_records_review_completed_by 
ON performance_records(review_completed_by);

-- 3. 기존 '완료' 상태 데이터 마이그레이션
UPDATE performance_records 
SET 
    review_completed_at = COALESCE(updated_at, created_at),
    review_completed_by = COALESCE(updated_by, registered_by)
WHERE review_status = '완료';

-- 4. 컬럼에 대한 설명 추가
COMMENT ON COLUMN performance_records.review_completed_at IS '검수 완료 시간 (review_status가 완료로 변경된 시점)';
COMMENT ON COLUMN performance_records.review_completed_by IS '검수 완료자 ID (review_status를 완료로 변경한 사용자)';

-- 5. 기존 트리거 확인 (있다면 삭제)
DROP TRIGGER IF EXISTS tr_performance_records_review_status ON performance_records;

-- 6. 새로운 트리거 생성
CREATE OR REPLACE FUNCTION update_review_completion()
RETURNS TRIGGER AS $$
BEGIN
    -- review_status가 '완료'로 변경된 경우
    IF NEW.review_status = '완료' AND (OLD.review_status IS NULL OR OLD.review_status != '완료') THEN
        NEW.review_completed_at = NOW();
        NEW.review_completed_by = auth.uid();
    
    -- review_status가 '완료'가 아닌 다른 상태로 변경된 경우
    ELSIF NEW.review_status != '완료' AND OLD.review_status = '완료' THEN
        NEW.review_completed_at = NULL;
        NEW.review_completed_by = NULL;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 트리거 생성
CREATE TRIGGER tr_performance_records_review_status
    BEFORE UPDATE ON performance_records
    FOR EACH ROW
    EXECUTE FUNCTION update_review_completion();

-- 7. 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'performance_records' 
AND column_name IN ('review_completed_at', 'review_completed_by')
ORDER BY column_name;

-- 8. 트리거 확인
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'performance_records'
AND trigger_name = 'tr_performance_records_review_status';

-- 9. 마이그레이션 결과 확인
SELECT 
    'Migration Result' as info,
    COUNT(*) as total_records,
    COUNT(CASE WHEN review_status = '완료' THEN 1 END) as completed_records,
    COUNT(CASE WHEN review_completed_at IS NOT NULL THEN 1 END) as records_with_completion_time,
    COUNT(CASE WHEN review_completed_by IS NOT NULL THEN 1 END) as records_with_completion_user
FROM performance_records;
