-- performance_records_absorption 테이블에 처방액과 지급액 컬럼 추가
-- 정산내역서 공유 기능에서 사용하기 위해 필요

-- 1. prescription_amount 컬럼 추가 (처방액)
ALTER TABLE performance_records_absorption 
ADD COLUMN prescription_amount numeric DEFAULT 0;

-- 2. payment_amount 컬럼 추가 (지급액)
ALTER TABLE performance_records_absorption 
ADD COLUMN payment_amount numeric DEFAULT 0;

-- 3. 기존 데이터에 대해 처방액과 지급액 계산하여 업데이트
UPDATE performance_records_absorption 
SET 
    prescription_amount = COALESCE(prescription_qty, 0) * COALESCE((
        SELECT price FROM products WHERE id = performance_records_absorption.product_id
    ), 0),
    payment_amount = COALESCE(prescription_qty, 0) * COALESCE((
        SELECT price FROM products WHERE id = performance_records_absorption.product_id
    ), 0) * COALESCE(commission_rate, 0) / 100
WHERE prescription_amount IS NULL OR payment_amount IS NULL;

-- 4. 컬럼에 인덱스 추가 (조회 성능 향상)
CREATE INDEX idx_performance_records_absorption_prescription_amount 
ON performance_records_absorption(prescription_amount);

CREATE INDEX idx_performance_records_absorption_payment_amount 
ON performance_records_absorption(payment_amount);

-- 5. 컬럼에 대한 설명 추가
COMMENT ON COLUMN performance_records_absorption.prescription_amount IS '처방액 (처방수량 * 제품가격)';
COMMENT ON COLUMN performance_records_absorption.payment_amount IS '지급액 (처방액 * 수수료율)';

-- 6. 변경사항 확인
SELECT 
    column_name, 
    data_type, 
    is_nullable, 
    column_default
FROM information_schema.columns 
WHERE table_name = 'performance_records_absorption' 
AND column_name IN ('prescription_amount', 'payment_amount')
ORDER BY column_name;

-- 7. 데이터 확인 (샘플)
SELECT 
    id,
    prescription_qty,
    prescription_amount,
    commission_rate,
    payment_amount
FROM performance_records_absorption 
WHERE prescription_amount > 0 OR payment_amount > 0
ORDER BY id
LIMIT 10;
