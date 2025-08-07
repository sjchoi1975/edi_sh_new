-- 정산내역서 관련 테이블에 전달사항 컬럼 추가

-- 1. settlement_months 테이블에 전체 대상 전달사항 컬럼 추가
ALTER TABLE settlement_months 
ADD COLUMN notice_payment TEXT;

-- 2. settlement_share 테이블에 개별 대상 전달사항 컬럼 추가
ALTER TABLE settlement_share 
ADD COLUMN notice_individual TEXT;

-- 3. 컬럼 설명 추가
COMMENT ON COLUMN settlement_months.notice_payment IS '전체 업체 대상 전달사항';
COMMENT ON COLUMN settlement_share.notice_individual IS '개별 업체 대상 전달사항'; 