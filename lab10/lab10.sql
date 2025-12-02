-- 3. PRACTICAL TASKS
-- 3.1
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE accounts (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    balance DECIMAL(10,2) DEFAULT 0.00
);

CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    shop VARCHAR(100) NOT NULL,
    product VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL
);

INSERT INTO accounts (name, balance) VALUES
('Alice', 1000.00),
('Bob', 500.00),
('Wally', 750.00);

INSERT INTO products (shop, product, price) VALUES
('Joe''s Shop', 'Coke', 2.50),
('Joe''s Shop', 'Pepsi', 3.00);


-- 3.2
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
COMMIT;

-- a) Alice = 900.00, Bob = 600.00
-- b) Both updates must be in one transaction to ensure atomicity.
-- c) Without a transaction, a crash may lead to money loss.


-- 3.3
BEGIN;
UPDATE accounts SET balance = balance - 500 WHERE name = 'Alice';
SELECT * FROM accounts WHERE name = 'Alice';
ROLLBACK;
SELECT * FROM accounts WHERE name = 'Alice';

-- a) Balance before rollback = 500.00
-- b) Balance after rollback = 1000.00
-- c) ROLLBACK is used to cancel incorrect or failed operations.


-- 3.4
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE name = 'Alice';
SAVEPOINT sp1;
UPDATE accounts SET balance = balance + 100 WHERE name = 'Bob';
ROLLBACK TO sp1;
UPDATE accounts SET balance = balance + 100 WHERE name = 'Wally';
COMMIT;

-- a) Alice = 900, Bob = 500, Wally = 850
-- b) Bob was credited but the change was rolled back.
-- c) SAVEPOINT allows partial rollback without cancelling all changes.


-- 3.5
-- SCENARIO A: READ COMMITTED
-- TERMINAL 1
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- TERMINAL 2
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
INSERT INTO products(shop, product, price)
VALUES ('Joe''s Shop','Fanta',3.50);
COMMIT;


-- SCENARIO B: SERIALIZABLE

-- TERMINAL 1
BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- TERMINAL 2
BEGIN;
DELETE FROM products WHERE shop='Joe''s Shop';
INSERT INTO products(shop, product, price)
VALUES ('Joe''s Shop','Fanta',3.50);
COMMIT;

-- a) Before COMMIT: Coke, Pepsi
--    After COMMIT:Fanta
-- b) Terminal 1 sees only Coke, Pepsi
-- c) READ COMMITTED shows latest committed data;
--    SERIALIZABLE works with a fixed snapshot.


-- 3.6
-- TERMINAL 1
BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- TERMINAL 2
BEGIN;
INSERT INTO products(shop, product, price)
VALUES ('Joe''s Shop','Sprite',4.00);
COMMIT;

-- a) New row NOT visible in Terminal 1
-- b) Phantom read = new rows appear in repeated query
-- c) Prevented by SERIALIZABLE


-- 3.7
-- TERMINAL 1
BEGIN TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SELECT * FROM products WHERE shop='Joe''s Shop';
SELECT * FROM products WHERE shop='Joe''s Shop';
COMMIT;

-- TERMINAL 2
BEGIN;
UPDATE products SET price=99.99 WHERE product='Fanta';
ROLLBACK;

-- a) Terminal 1 may see uncommitted 99.99
-- b) Dirty read = reading uncommitted data
-- c) READ UNCOMMITTED causes inconsistent results


-- 4. INDEPENDENT EXERCISES
-- Exercise 1:
DO $$
BEGIN
    IF (SELECT balance FROM accounts WHERE name='Bob') >= 200 THEN
        BEGIN
            UPDATE accounts SET balance = balance - 200 WHERE name='Bob';
            UPDATE accounts SET balance = balance + 200 WHERE name='Wally';
            RAISE NOTICE 'Transfer successful';
        END;
    ELSE
        RAISE NOTICE 'Transfer failed: insufficient funds';
    END IF;
END $$;
SELECT * FROM accounts;

-- Exercise 2:
BEGIN;
INSERT INTO products (shop, product, price)
VALUES ('Demo Shop','Tea',1.00);
SAVEPOINT s1;
UPDATE products SET price = 2.50 WHERE product='Tea';
SAVEPOINT s2;
DELETE FROM products WHERE product='Tea';
ROLLBACK TO s1;
COMMIT;
-- Final state: Tea exists with price = 1.00

-- Exercise 3
-- TERMINAL 1:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;

-- TERMINAL 2:
BEGIN TRANSACTION ISOLATION LEVEL READ COMMITTED;
UPDATE accounts SET balance = balance - 300 WHERE name='Alice';
COMMIT;
-- Under SERIALIZABLE, second transaction would fail.


-- Exercise 4
-- BAD SESSION 1:
SELECT MAX(price) FROM products WHERE shop='Joe''s Shop';
-- Meanwhile SESSION 2 deletes rows

-- BAD RESULT: MAX < MIN possible

-- GOOD (WITH TRANSACTION):
BEGIN;
SELECT MAX(price), MIN(price) FROM products WHERE shop='Joe''s Shop';
COMMIT;



-- 5. SELF-ASSESSMENT QUESTIONS

-- 1. Explain each ACID property with example.
-- Atomicity: bank transfer succeeds fully or fails.
-- Consistency: constraints remain valid.
-- Isolation: users do not see intermediate results.
-- Durability: committed data survives crashes.

-- 2. Difference between COMMIT and ROLLBACK.
-- COMMIT saves changes permanently.
-- ROLLBACK cancels changes since BEGIN.

-- 3. When would you use SAVEPOINT?
-- When only part of a transaction must be undone.

-- 4. Compare all isolation levels.
-- READ UNCOMMITTED: dirty reads allowed.
-- READ COMMITTED: no dirty reads.
-- REPEATABLE READ: stable rows.
-- SERIALIZABLE: full isolation.

-- 5. What is a dirty read and which level allows it?
-- Dirty read is reading uncommitted data.
-- Allowed in READ UNCOMMITTED.

-- 6. What is a non-repeatable read?
-- When a row read twice has different values.

-- 7. What is a phantom read?
-- When new rows appear in repeated query results.

-- 8. Which isolation levels prevent phantom reads?
-- Only SERIALIZABLE fully prevents phantom reads.

-- 9. Why use READ COMMITTED in high-load systems?
-- It provides good performance with acceptable consistency.

-- 10. What happens to uncommitted data after crash?
-- All uncommitted changes are lost.


--CONCLUSION
/*This laboratory work demonstrated how transactions and isolation levels
 ensure data consistency and reliability. ACID properties were studied
 along with practical usage of transaction control commands in concurrent
 database environments. */

