CREATE DATABASE advanced_lab;

\c advanced_lab;

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50) UNIQUE,
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    dept_id INT REFERENCES departments(dept_id),
    salary INTEGER DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER REFERENCES departments(dept_id),
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
  ('IT', 200000, 1),
  ('HR', 100000, 2),
  ('Sales', 150000, 3),
  ('Management', 250000, 4),
  ('Senior', 180000, 5),
  ('Junior', 80000, 6),
  ('Unassigned', 0, NULL);

INSERT INTO employees (emp_id, first_name, last_name, dept_id)
VALUES (1, 'John', 'Doe', (SELECT dept_id FROM departments WHERE dept_name='IT'));

INSERT INTO employees (first_name, last_name, hire_date)
VALUES ('Alice', 'Smith', CURRENT_DATE);

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date)
VALUES ('Bob', 'Brown', (SELECT dept_id FROM departments WHERE dept_name='HR'), 50000 * 1.1, CURRENT_DATE);

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name='IT');

UPDATE employees SET salary = salary * 1.10;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

UPDATE employees
SET dept_id = CASE
    WHEN salary > 80000 THEN (SELECT dept_id FROM departments WHERE dept_name='Management')
    WHEN salary BETWEEN 50000 AND 80000 THEN (SELECT dept_id FROM departments WHERE dept_name='Senior')
    ELSE (SELECT dept_id FROM departments WHERE dept_name='Junior')
END;

UPDATE employees
SET dept_id = (SELECT dept_id FROM departments WHERE dept_name='Unassigned')
WHERE status = 'Inactive';

UPDATE departments d
SET budget = (SELECT AVG(salary) * 1.2
              FROM employees e
              WHERE e.dept_id = d.dept_id);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name='Sales');

DELETE FROM employees WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND dept_id IS NULL;

DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT dept_id FROM employees WHERE dept_id IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, salary, dept_id)
VALUES ('NullGuy', 'Test', NULL, NULL);

UPDATE employees
SET dept_id = (SELECT dept_id FROM departments WHERE dept_name='Unassigned')
WHERE dept_id IS NULL;

DELETE FROM employees
WHERE salary IS NULL OR dept_id IS NULL;

INSERT INTO employees (first_name, last_name, hire_date, dept_id)
VALUES ('Charlie', 'Wilson', CURRENT_DATE, (SELECT dept_id FROM departments WHERE dept_name='HR'))
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE dept_id = (SELECT dept_id FROM departments WHERE dept_name='IT')
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

INSERT INTO employees (first_name, last_name, hire_date, dept_id)
SELECT 'Diana', 'Prince', CURRENT_DATE, (SELECT dept_id FROM departments WHERE dept_name='HR')
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name='Diana' AND last_name='Prince'
);

UPDATE employees e
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_id=e.dept_id) > 100000 THEN 1.10
    ELSE 1.05
END;

INSERT INTO employees (first_name, last_name, dept_id, salary, hire_date)
VALUES 
 ('E1', 'Test', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 45000, CURRENT_DATE),
 ('E2', 'Test', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 46000, CURRENT_DATE),
 ('E3', 'Test', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 47000, CURRENT_DATE),
 ('E4', 'Test', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 48000, CURRENT_DATE),
 ('E5', 'Test', (SELECT dept_id FROM departments WHERE dept_name='Sales'), 49000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Test';

CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE 1=0;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status='Inactive';

DELETE FROM employees WHERE status='Inactive';

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (SELECT COUNT(*) FROM employees e WHERE e.dept_id=p.dept_id) > 3;