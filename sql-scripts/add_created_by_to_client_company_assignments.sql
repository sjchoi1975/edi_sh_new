-- client_company_assignments 테이블에 created_by 컬럼 추가
-- 이 스크립트는 일괄 변경 기능에서 매핑 관계 추가 시 사용자 정보를 기록하기 위해 필요합니다.

-- 1단계: created_by 컬럼 추가 (UUID 타입, NULL 허용)
ALTER TABLE client_company_assignments 
ADD COLUMN created_by UUID REFERENCES auth.users(id);

-- 2단계: 기존 데이터의 created_by를 기본 관리자로 설정
UPDATE client_company_assignments 
SET created_by = '0e085a22-2267-4e7a-9c1e-5c7bf4f3034a'::UUID 
WHERE created_by IS NULL;

-- 3단계: created_by 컬럼에 대한 인덱스 생성 (선택사항, 성능 향상을 위해)
CREATE INDEX idx_client_company_assignments_created_by ON client_company_assignments(created_by);

-- 4단계: 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'client_company_assignments' 
AND column_name = 'created_by'; 