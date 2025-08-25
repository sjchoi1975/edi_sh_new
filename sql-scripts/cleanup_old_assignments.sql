-- 기존 제품별 할당 테이블 및 함수 정리
-- 2025-01-07

-- 1. 기존 함수들 삭제
DROP FUNCTION IF EXISTS get_product_company_assignments(uuid);
DROP FUNCTION IF EXISTS update_product_company_assignments(uuid, json);

-- 2. 기존 테이블 삭제 (데이터 백업 후)
-- 주의: 이 작업은 되돌릴 수 없으므로 신중하게 실행하세요!

-- 먼저 데이터 백업 (선택사항)
CREATE TABLE IF NOT EXISTS product_company_assignments_backup AS 
SELECT * FROM product_company_assignments;

-- 기존 테이블 삭제
DROP TABLE IF EXISTS product_company_assignments;

-- 3. 기존 트리거 함수 삭제 (더 이상 사용하지 않는 경우)
-- DROP FUNCTION IF EXISTS update_product_company_assignments_updated_at();

-- 4. 정리 완료 메시지
SELECT '기존 제품별 할당 테이블 정리가 완료되었습니다.' as message; 