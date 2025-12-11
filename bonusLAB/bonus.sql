DROP TABLE IF EXISTS salary_batches CASCADE;
DROP TABLE IF EXISTS audit_log CASCADE;
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS exchange_rates CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS customers CASCADE;

--Table creation
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    iin CHAR(12) UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    status TEXT NOT NULL CHECK (status IN ('active','blocked','frozen')),
    created_at TIMESTAMPTZ DEFAULT now(),
    daily_limit_kzt NUMERIC(20,2) DEFAULT 2000000
);

CREATE TABLE accounts (
    account_id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(customer_id),
    account_number TEXT UNIQUE NOT NULL CHECK (account_number ~ '^[A-Z]{2}[0-9]{2}[A-Z0-9]{10,30}$'),
    currency CHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    balance  NUMERIC(20,2) NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    opened_at TIMESTAMPTZ DEFAULT now(),
    closed_at TIMESTAMPTZ
);

CREATE TABLE exchange_rates (
    rate_id SERIAL PRIMARY KEY,
    from_currency CHAR(3) NOT NULL CHECK (from_currency IN ('KZT','USD','EUR','RUB')),
    to_currency CHAR(3) NOT NULL CHECK (to_currency IN ('KZT','USD','EUR','RUB')),
    rate NUMERIC(30,10) NOT NULL,
    valid_from TIMESTAMPTZ NOT NULL DEFAULT now(),
    valid_to TIMESTAMPTZ
);

CREATE TABLE transactions (
    transaction_id SERIAL PRIMARY KEY,
    from_account_id INT REFERENCES accounts(account_id),
    to_account_id INT REFERENCES accounts(account_id),
    amount NUMERIC(20,2) NOT NULL,
    currency CHAR(3) NOT NULL CHECK (currency IN ('KZT','USD','EUR','RUB')),
    exchange_rate NUMERIC(30,10),
    amount_kzt NUMERIC(30,2),
    type TEXT NOT NULL CHECK (type IN ('transfer','deposit','withdrawal','salary')),
    status TEXT NOT NULL CHECK (status IN ('pending','completed','failed','reversed')),
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    description TEXT
);

CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name TEXT NOT NULL,
    record_id TEXT,
    action TEXT NOT NULL CHECK (action IN ('INSERT','UPDATE','DELETE')),
    old_values JSONB,
    new_values JSONB,
    changed_by TEXT,
    changed_at TIMESTAMPTZ DEFAULT now(),
    ip_address TEXT
);

--This table is required for task4
CREATE TABLE salary_batches (
    batch_id SERIAL PRIMARY KEY,
    company_account_id INT NOT NULL REFERENCES accounts(account_id),
    created_at TIMESTAMPTZ DEFAULT now(),
    total_amount NUMERIC(20,2),
    successful_count INT,
    failed_count INT,
    failed_details JSONB
);

--Insertion
INSERT INTO customers (iin, full_name, phone, email, status, daily_limit_kzt) VALUES
('070707000001','Nurdan Z','+77757711975','nuranzhangabai@gmail.com','active', 2000000),
('070707000002','Kunsulu Y','+77083927027','kuns@gmail.com','active', 1500000),
('070707000003','Erlan T','+77059797245','erlan.toksanbay@gmail.com','blocked', 1000000),
('070707000004','Oren Y','+77009809883','proqazaq123@gmail.com','active', 3000000),
('070707000005','Madina T','+77073203292','madinaturkebay@gmail.com','frozen',  500000),
('070707000006','Marlen Y','+77073082210','marlentktl@gmail.com','active', 5000000),
('070707000007','Samira U','+77476887834','urmanova@gmail.com','active',  750000),
('070707000008','Inkar K','+77753354765','inkar@gmail.com','active', 1200000),
('070707000009','Eltilek O','+77764159441','tilekormanov@gmail.com','active',  900000),
('070707000010','Emelzhan E','+77070000010','emel@gmail.com','active',  800000);

INSERT INTO accounts (customer_id, account_number, currency, balance, is_active) VALUES
(1,'KZ1201BANK0000000001','KZT', 800000, TRUE),
(1,'GB12BANK000000000001','USD',  2000, TRUE),
(2,'KZ1201BANK0000000002','KZT', 300000, TRUE),
(3,'KZ1201BANK0000000003','KZT', 100000, TRUE),
(4,'DE12BANK000000000001','EUR',   800, TRUE),
(4,'KZ1201BANK0000000004','KZT', 150000, TRUE),
(5,'KZ1201BANK0000000005','KZT',  50000, TRUE),
(6,'KZ1201BANK0000000006','KZT',3000000, TRUE),
(7,'KZ1201BANK0000000007','KZT', 600000, TRUE),
(8,'KZ1201BANK0000000008','KZT', 250000, TRUE),
(9,'KZ1201BANK0000000009','KZT', 100000, TRUE),
(10,'KZ1201BANK0000000010','KZT',200000, FALSE);

INSERT INTO exchange_rates (from_currency, to_currency, rate, valid_from, valid_to) VALUES
('USD','KZT',470, now() - interval '10 day', NULL),
('EUR','KZT',510, now() - interval '10 day', NULL),
('RUB','KZT',5.5, now() - interval '10 day', NULL),
('KZT','USD',1/470.0, now() - interval '10 day', NULL),
('KZT','EUR',1/510.0, now() - interval '10 day', NULL),
('KZT','RUB',1/5.5,  now() - interval '10 day', NULL),
('USD','EUR',470.0/510.0, now() - interval '10 day', NULL),
('EUR','USD',510.0/470.0, now() - interval '10 day', NULL),
('USD','RUB',470.0/5.5,   now() - interval '10 day', NULL),
('RUB','USD',5.5/470.0,   now() - interval '10 day', NULL);

INSERT INTO transactions (from_account_id,to_account_id,amount,currency,amount_kzt,exchange_rate,type,status,created_at,description)
VALUES
(1,2, 50000,'KZT', 50000,1,'transfer','completed',now()-interval '2 day','test'),
(1,3, 20000,'KZT', 20000,1,'transfer','completed',now()-interval '1 day','test'),
(2,1,  100,'USD', 47000,470,'transfer','completed',now()-interval '1 day','usd->kzt'),
(6,7, 300000,'KZT',300000,1,'salary','completed',now()-interval '1 day','salary'),
(6,8, 150000,'KZT',150000,1,'salary','completed',now()-interval '1 day','salary'),
(1,4,  1000,'KZT', 1000,1,'transfer','failed',now()-interval '3 hour','failed'),
(1,7, 2000000,'KZT',2000000,1,'transfer','completed',now()-interval '1 hour','big'),
(1,7,  10000,'KZT', 10000,1,'transfer','completed',now()-interval '50 minute','fast1'),
(1,7,  12000,'KZT', 12000,1,'transfer','completed',now()-interval '49 minute','fast2'),
(7,8,  9000,'KZT',  9000,1,'transfer','completed',now()-interval '10 minute','small');

--suppose we already have some data in audit_log
INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
VALUES
('accounts','1','INSERT',NULL,jsonb_build_object('balance',800000),'system'),
('customers','1','INSERT',NULL,jsonb_build_object('status','active'),'system');


--helper function used for currency conversion in transfers, limits, and salary batches.
CREATE OR REPLACE FUNCTION get_latest_rate(p_from CHAR(3), p_to CHAR(3))
RETURNS NUMERIC AS $$
DECLARE
    r NUMERIC;
BEGIN
    IF p_from = p_to THEN
        RETURN 1;
    END IF;

    SELECT rate INTO r
    FROM exchange_rates
    WHERE from_currency = p_from
      AND to_currency   = p_to
      AND (valid_to IS NULL OR valid_to > now())
      AND valid_from <= now()
    ORDER BY valid_from DESC
    LIMIT 1;

    IF r IS NULL THEN
        RAISE EXCEPTION 'EXCHANGE_RATE_NOT_FOUND % -> %', p_from, p_to
            USING ERRCODE = 'P0001';
    END IF;

    RETURN r;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION process_transfer(
    p_from_account_number TEXT,
    p_to_account_number TEXT,
    p_amount NUMERIC,
    p_currency CHAR(3),
    p_description TEXT
)
RETURNS TABLE(error_code TEXT, error_message TEXT, created_transaction_id INT)
AS $$
DECLARE
    acc_from accounts%ROWTYPE;
    acc_to accounts%ROWTYPE;
    cust_from customers%ROWTYPE;
    rate_to_kzt NUMERIC;
    amount_kzt NUMERIC;
    today_sum NUMERIC;
    debit_amount NUMERIC;
    credit_amount NUMERIC;
    tx_id INT;
BEGIN
--Validate amount
    IF p_amount <= 0 THEN
        error_code := 'INVALID_AMOUNT';
        error_message := 'Amount must be positive';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;
--Load FROM account
    SELECT * INTO acc_from
    FROM accounts
    WHERE account_number = p_from_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        error_code := 'FROM_NOT_FOUND';
        error_message := 'Source account not found';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Load TO account
    SELECT * INTO acc_to
    FROM accounts
    WHERE account_number = p_to_account_number
    FOR UPDATE;

    IF NOT FOUND THEN
        error_code := 'TO_NOT_FOUND';
        error_message := 'Destination account not found';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Account activity checks
    IF NOT acc_from.is_active THEN
        error_code := 'FROM_INACTIVE';
        error_message := 'Source account inactive';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

    IF NOT acc_to.is_active THEN
        error_code := 'TO_INACTIVE';
        error_message := 'Destination account inactive';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Customer must be active
    SELECT * INTO cust_from
    FROM customers
    WHERE customer_id = acc_from.customer_id;

    IF cust_from.status <> 'active' THEN
        error_code := 'CUSTOMER_NOT_ACTIVE';
        error_message := 'Customer is not active';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Check daily limit in KZT
    rate_to_kzt := get_latest_rate(p_currency, 'KZT');
    amount_kzt := ROUND(p_amount * rate_to_kzt, 2);

    -- daily limit check
SELECT COALESCE(SUM(t.amount_kzt), 0)
INTO today_sum
FROM transactions t
WHERE t.from_account_id = acc_from.account_id
  AND t.created_at::date = now()::date
  AND t.status IN ('pending','completed');


    IF today_sum + amount_kzt > cust_from.daily_limit_kzt THEN
        error_code := 'DAILY_LIMIT_EXCEEDED';
        error_message := 'Daily transaction limit exceeded';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Check if source has enough money
    IF p_currency = acc_from.currency THEN
        debit_amount := p_amount;
    ELSE
        debit_amount := ROUND(p_amount * get_latest_rate(p_currency, acc_from.currency), 2);
    END IF;

    IF acc_from.balance < debit_amount THEN
        error_code := 'INSUFFICIENT_FUNDS';
        error_message := 'Insufficient balance';
        created_transaction_id := NULL;
        RETURN NEXT;
        RETURN;
    END IF;

--Insert pending transaction row
    INSERT INTO transactions(from_account_id,to_account_id,amount,currency,
                             exchange_rate,amount_kzt,type,status,description)
    VALUES (acc_from.account_id, acc_to.account_id, p_amount, p_currency,
            rate_to_kzt, amount_kzt, 'transfer','pending',p_description)
    RETURNING transaction_id INTO tx_id;

--Update balances
    UPDATE accounts
    SET balance = balance - debit_amount
    WHERE account_id = acc_from.account_id;

    IF p_currency = acc_to.currency THEN
        credit_amount := p_amount;
    ELSE
        credit_amount := ROUND(p_amount * get_latest_rate(p_currency, acc_to.currency), 2);
    END IF;

    UPDATE accounts
    SET balance = balance + credit_amount
    WHERE account_id = acc_to.account_id;

    UPDATE transactions
    SET status = 'completed', completed_at = now()
    WHERE transaction_id = tx_id;

    error_code := 'OK';
    error_message := 'Transfer completed successfully';
    created_transaction_id := tx_id;

    RETURN NEXT;
    RETURN;
END;
$$ LANGUAGE plpgsql;




--Task2
-- View 1:customer_balance_summary
CREATE OR REPLACE VIEW customer_balance_summary AS
WITH acc_kzt AS (
    SELECT
        a.account_id,
        a.customer_id,
        a.account_number,
        a.currency,
        a.balance,
        a.is_active,
        a.opened_at,
        COALESCE(
            a.balance * get_latest_rate(a.currency,'KZT'),
            a.balance
        )::NUMERIC(20,2) AS balance_kzt
    FROM accounts a
),
base AS (
    SELECT
        c.customer_id,
        c.full_name,
        c.iin,
        c.email,
        ak.account_id,
        ak.account_number,
        ak.currency,
        ak.balance,
        ak.balance_kzt,
        SUM(ak.balance_kzt) OVER (PARTITION BY c.customer_id) AS total_balance_kzt,
        ROUND(
            COALESCE((
                SELECT SUM(t.amount_kzt)
                FROM transactions t
                JOIN accounts a2 ON t.from_account_id = a2.account_id
                WHERE a2.customer_id = c.customer_id
                  AND t.created_at::date = now()::date
                  AND t.status IN ('pending','completed')
            ),0) * 100.0 / NULLIF(c.daily_limit_kzt,0),
        2) AS daily_limit_util_pct
    FROM customers c
    JOIN acc_kzt ak ON ak.customer_id = c.customer_id
)
SELECT
    *,
    RANK() OVER (ORDER BY total_balance_kzt DESC) AS rank_by_total
FROM base;


-- View 2:daily_transaction_report
CREATE OR REPLACE VIEW daily_transaction_report AS
WITH base AS (
    SELECT
        date_trunc('day', created_at)::date AS tx_date,
        type,
        SUM(amount_kzt) AS total_volume_kzt,
        COUNT(*) AS tx_count,
        AVG(amount_kzt) AS avg_amount_kzt
    FROM transactions
    GROUP BY date_trunc('day', created_at), type
),
agg AS (
    SELECT
        tx_date,
        type,
        total_volume_kzt,
        tx_count,
        avg_amount_kzt,
        SUM(total_volume_kzt) OVER (ORDER BY tx_date) AS running_total_kzt,
        LAG(total_volume_kzt) OVER (ORDER BY tx_date) AS prev_day_volume
    FROM base
)
SELECT
    tx_date,
    type,
    total_volume_kzt,
    tx_count,
    avg_amount_kzt,
    running_total_kzt,
    ROUND(
      (total_volume_kzt - COALESCE(prev_day_volume,0)) * 100.0 /
      NULLIF(prev_day_volume,0)
    ,2) AS day_over_day_growth_pct
FROM agg
ORDER BY tx_date DESC, type;


-- View 3:suspicious_activity_view (with security barrier)
CREATE OR REPLACE VIEW suspicious_activity_view
WITH (security_barrier = true) AS
WITH big_tx AS (
    SELECT t.transaction_id
    FROM transactions t
    WHERE t.amount_kzt >= 5000000
),
hourly_counts AS (
    SELECT
        from_account_id,
        date_trunc('hour', created_at) AS hour_slot,
        COUNT(*) AS tx_count
    FROM transactions
    GROUP BY from_account_id, date_trunc('hour', created_at)
    HAVING COUNT(*) > 10
),
rapid_seq AS (
    SELECT t1.transaction_id
    FROM transactions t1
    JOIN transactions t2
      ON t1.from_account_id = t2.from_account_id
     AND t1.transaction_id <> t2.transaction_id
     AND ABS(EXTRACT(EPOCH FROM (t1.created_at - t2.created_at))) < 60
)
SELECT
    t.*,
    CASE
      WHEN t.transaction_id IN (SELECT transaction_id FROM big_tx) THEN 'LARGE_TRANSFER'
      WHEN EXISTS (
          SELECT 1 FROM hourly_counts hc
          WHERE hc.from_account_id = t.from_account_id
            AND hc.hour_slot = date_trunc('hour', t.created_at)
      ) THEN 'FREQUENT_IN_HOUR'
      WHEN t.transaction_id IN (SELECT transaction_id FROM rapid_seq) THEN 'RAPID_SEQUENTIAL'
      ELSE 'OK'
    END AS suspicious_flag
FROM transactions t
WHERE
      t.transaction_id IN (SELECT transaction_id FROM big_tx)
   OR t.transaction_id IN (SELECT transaction_id FROM rapid_seq)
   OR EXISTS (
        SELECT 1 FROM hourly_counts hc
        WHERE hc.from_account_id = t.from_account_id
          AND hc.hour_slot = date_trunc('hour', t.created_at)
   );



--Task3 Indexes

-- FK index / composite B-tree (customer_id, currency)
CREATE INDEX IF NOT EXISTS idx_accounts_customer_currency
ON accounts (customer_id, currency);

--Partial index for active accounts only
CREATE INDEX IF NOT EXISTS idx_accounts_active
ON accounts (customer_id)
WHERE is_active = TRUE;

--Expression index for case-insensitive email search
CREATE INDEX IF NOT EXISTS idx_customers_email_lower
ON customers ((lower(email)));

--Hash index on IIN
--Hash index gives faster equality search compared to B-tree for long strings.
CREATE INDEX IF NOT EXISTS idx_customers_iin_hash
ON customers USING HASH (iin);

--GIN index on JSONB columns in audit_log
CREATE INDEX IF NOT EXISTS idx_audit_log_jsonb
ON audit_log USING GIN (new_values, old_values);

--Covering index for frequent pattern:
--"all transactions for account ordered by created_at"
CREATE INDEX IF NOT EXISTS idx_tx_from_account_date
ON transactions (from_account_id, created_at DESC)
INCLUDE (status, amount_kzt, type);

--Simple B-tree for amount_kzt (range queries)
CREATE INDEX IF NOT EXISTS idx_tx_amount_kzt
ON transactions (amount_kzt);

--explain analyze for all indexes

--idx_accounts_customer_currency
EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE customer_id = 1 AND currency = 'KZT';

--idx_accounts_active
EXPLAIN ANALYZE
SELECT *
FROM accounts
WHERE customer_id = 1 AND is_active = TRUE;


--idx_customers_email_lower
EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE lower(email) = lower('kuns@gmail.com');


--idx_customers_iin_hash
EXPLAIN ANALYZE
SELECT *
FROM customers
WHERE iin = '070707000001';


--idx_audit_log_jsonb
EXPLAIN ANALYZE
SELECT *
FROM audit_log
WHERE new_values @> '{"status":"completed"}';


--idx_tx_from_account_date
EXPLAIN ANALYZE SELECT status, amount_kzt, type
FROM transactions
WHERE from_account_id = 1
ORDER BY created_at DESC
LIMIT 20;


--idx_tx_amount_kzt
EXPLAIN ANALYZE SELECT *
FROM transactions
WHERE amount_kzt > 100000;


--Task4 Batch processing
CREATE OR REPLACE FUNCTION process_salary_batch(
    p_company_account_number TEXT,
    p_payments JSONB
)
RETURNS JSONB AS $$
DECLARE
    company_acc accounts%ROWTYPE;
    batch_total NUMERIC(20,2) := 0;
    elem JSONB;
    emp_cust customers%ROWTYPE;
    emp_acc accounts%ROWTYPE;
    ok_count INT := 0;
    fail_count INT := 0;
    fail_details JSONB := '[]'::jsonb;
    lock_key BIGINT;
BEGIN
    lock_key := hashtext(p_company_account_number); -- Prevent concurrent salary batches for same company account
    PERFORM pg_advisory_xact_lock(lock_key);

    SELECT * INTO company_acc
    FROM accounts
    WHERE account_number = p_company_account_number
      AND is_active = TRUE
    FOR UPDATE;
    IF company_acc.account_id IS NULL THEN
        RETURN jsonb_build_object('error','COMPANY_ACCOUNT_NOT_FOUND');
    END IF;
-- Calculate total required salary amount
    FOR elem IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        batch_total := batch_total + COALESCE((elem->>'amount')::NUMERIC,0);
    END LOOP;

-- Ensure company balance is sufficient for full salary batch
    IF batch_total > company_acc.balance THEN
        RETURN jsonb_build_object(
            'error','INSUFFICIENT_COMPANY_FUNDS',
            'required',batch_total,
            'available',company_acc.balance
        );
    END IF;

--Temporary table to accumulate balance updates atomically
    CREATE TEMP TABLE tmp_salary_deltas(
        account_id INT PRIMARY KEY,
        delta NUMERIC(20,2)
    ) ON COMMIT DROP;

    FOR elem IN SELECT * FROM jsonb_array_elements(p_payments)
    LOOP
        BEGIN
            SAVEPOINT sp_one;

            IF COALESCE((elem->>'amount')::NUMERIC,0) <= 0 THEN
                fail_count := fail_count + 1;
                fail_details := fail_details || jsonb_build_array(
                    jsonb_build_object('iin',elem->>'iin','error','INVALID_AMOUNT')
                );
                --ROLLBACK TO SAVEPOINT sp_one;
                CONTINUE;
            END IF;

            SELECT * INTO emp_cust
            FROM customers
            WHERE iin = LPAD(elem->>'iin',12,'0');

            IF emp_cust.customer_id IS NULL THEN
                fail_count := fail_count + 1;
                fail_details := fail_details || jsonb_build_array(
                    jsonb_build_object('iin',elem->>'iin','error','CUSTOMER_NOT_FOUND')
                );
                --ROLLBACK TO SAVEPOINT sp_one;
                CONTINUE;
            END IF;

            SELECT *
            INTO emp_acc
            FROM accounts
            WHERE customer_id = emp_cust.customer_id
              AND is_active = TRUE
            ORDER BY (currency = 'KZT') DESC, opened_at
            LIMIT 1;

            IF emp_acc.account_id IS NULL THEN
                fail_count := fail_count + 1;
                fail_details := fail_details || jsonb_build_array(
                    jsonb_build_object('iin',emp_cust.iin,'error','NO_ACTIVE_ACCOUNT')
                );
                --ROLLBACK TO SAVEPOINT sp_one;
                CONTINUE;
            END IF;

            INSERT INTO tmp_salary_deltas(account_id, delta)
            VALUES (company_acc.account_id, -(elem->>'amount')::NUMERIC)
            ON CONFLICT (account_id)
            DO UPDATE SET delta = tmp_salary_deltas.delta + EXCLUDED.delta;

            INSERT INTO tmp_salary_deltas(account_id, delta)
            VALUES (emp_acc.account_id, (elem->>'amount')::NUMERIC)
            ON CONFLICT (account_id)
            DO UPDATE SET delta = tmp_salary_deltas.delta + EXCLUDED.delta;

            -- insert transaction immediately (type salary, without daily limit)
            INSERT INTO transactions(from_account_id,to_account_id,amount,currency,exchange_rate,amount_kzt,type,status,description)
            VALUES (
                company_acc.account_id,
                emp_acc.account_id,
                (elem->>'amount')::NUMERIC,
                emp_acc.currency,
                get_latest_rate(emp_acc.currency,'KZT'),
                (elem->>'amount')::NUMERIC * get_latest_rate(emp_acc.currency,'KZT'),
                'salary',
                'completed',
                COALESCE(elem->>'description','salary payment')
            );

            ok_count := ok_count + 1;

            RELEASE SAVEPOINT sp_one;
        EXCEPTION WHEN OTHERS THEN -- Capture unexpected errors
            --ROLLBACK TO SAVEPOINT sp_one;
            fail_count := fail_count + 1;
            fail_details := fail_details || jsonb_build_array(
                jsonb_build_object('iin',elem->>'iin','error',SQLERRM)
            );
        END;
    END LOOP;

    UPDATE accounts a
    SET balance = a.balance + d.delta
    FROM tmp_salary_deltas d
    WHERE a.account_id = d.account_id;

    --batch summary
    INSERT INTO salary_batches(company_account_id,total_amount,successful_count,failed_count,failed_details)
    VALUES (company_acc.account_id, batch_total, ok_count, fail_count, fail_details);

    RETURN jsonb_build_object(
        'company_account', p_company_account_number,
        'total_amount', batch_total,
        'successful_count', ok_count,
        'failed_count', fail_count,
        'failed_details', fail_details
    );
END;
$$ LANGUAGE plpgsql;


-- Materialized view to see salary batch summaries
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_salary_batches AS
SELECT
    sb.batch_id,
    a.account_number AS company_account_number,
    sb.created_at,
    sb.total_amount,
    sb.successful_count,
    sb.failed_count,
    sb.failed_details
FROM salary_batches sb
JOIN accounts a ON a.account_id = sb.company_account_id
WITH NO DATA;

REFRESH MATERIALIZED VIEW mv_salary_batches;


--test cases
UPDATE transactions
SET created_at = now() - interval '2 day'
WHERE description IN ('big','fast1','fast2');


--successful transfer
SELECT * FROM process_transfer('KZ1201BANK0000000001','KZ1201BANK0000000002',50000,'KZT','test ok');

--insufficient limit
SELECT * FROM process_transfer('KZ1201BANK0000000006','KZ1201BANK0000000002',9999999,'KZT','daily limit');

--blocked / frozen customer
-- customer_id 3 or 5 in my sample data
SELECT * FROM process_transfer('KZ1201BANK0000000003','KZ1201BANK0000000002',1000,'KZT','blocked');


--salary batch
SELECT process_salary_batch(
'KZ1201BANK0000000006',
'[{"iin":"070707000001","amount":100000,"description":"Dec salary"},
            {"iin":"070707000002","amount":120000,"description":"Dec salary"},
            {"iin":"999999999999","amount":50000,"description":"no such"}]'::jsonb
);

 REFRESH MATERIALIZED VIEW mv_salary_batches;
 SELECT * FROM mv_salary_batches;





