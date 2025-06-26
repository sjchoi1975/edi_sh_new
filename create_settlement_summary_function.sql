CREATE OR REPLACE FUNCTION public.get_settlement_summary_by_company(p_settlement_month text)
RETURNS TABLE(
    company_id uuid,
    company_type text,
    company_name text,
    business_registration_number text,
    representative_name text,
    manager_name text,
    client_count bigint,
    prescription_count bigint,
    total_prescription_amount double precision,
    total_payment_amount double precision,
    is_shared boolean,
    settlement_share_id bigint
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    WITH summary AS (
        SELECT
            c.id AS company_id,
            c.company_type,
            c.company_name,
            c.business_registration_number,
            c.representative_name,
            c.manager_name,
            COUNT(DISTINCT aa.client_id) AS client_count,
            COUNT(*) AS prescription_count,
            SUM(aa.prescription_amount)::double precision AS total_prescription_amount,
            SUM(ROUND((aa.prescription_amount * aa.commission_rate)))::double precision AS total_payment_amount
        FROM
            public.absorption_analysis aa
        JOIN
            public.companies c ON aa.company_id = c.id
        WHERE
            aa.settlement_month = p_settlement_month
            AND aa.user_edit_status = '완료'
        GROUP BY
            c.id
    )
    SELECT
        s.company_id,
        s.company_type,
        s.company_name,
        s.business_registration_number,
        s.representative_name,
        s.manager_name,
        s.client_count,
        s.prescription_count,
        s.total_prescription_amount,
        s.total_payment_amount,
        COALESCE(ss.share_enabled, false) AS is_shared,
        ss.id AS settlement_share_id
    FROM
        summary s
    LEFT JOIN
        public.settlement_share ss ON s.company_id = ss.company_id AND ss.settlement_month = p_settlement_month;
END;
$$; 