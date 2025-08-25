-- performance_records_absorption 테이블에 analysis_time 컬럼 추가
-- 흡수율 분석 실행 시간을 기록하여 재분석 필요성 체크의 기준으로 사용

-- 1. analysis_time 컬럼 추가
ALTER TABLE performance_records_absorption 
ADD COLUMN analysis_time timestamptz;

-- 2. 기존 데이터의 analysis_time을 updated_at으로 초기화 (기존 분석 데이터가 있다고 가정)
UPDATE performance_records_absorption 
SET analysis_time = updated_at 
WHERE analysis_time IS NULL;

-- 3. analysis_time 컬럼에 인덱스 추가 (조회 성능 향상)
CREATE INDEX idx_performance_records_absorption_analysis_time 
ON performance_records_absorption(analysis_time);

-- 4. analysis_time 컬럼에 대한 설명 추가
COMMENT ON COLUMN performance_records_absorption.analysis_time IS '흡수율 분석 실행 시간. 재분석 필요성 체크의 기준으로 사용됨.';

-- 5. 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'performance_records_absorption' 
AND column_name = 'analysis_time';
