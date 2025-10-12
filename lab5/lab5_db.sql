
-- Task 1.1
CREATE TABLE employees (
    employee_id INT,
    first_name TEXT,
    last_name TEXT,
    age INT CHECK (age BETWEEN 18 AND 65),
    salary NUMERIC CHECK (salary > 0)
);

INSERT INTO employees VALUES (1, 'John', 'Smith', 30, 5000);
INSERT INTO employees VALUES (2, 'Jane', 'Doe', 40, 7000);
-- INVALID: age < 18
-- INSERT INTO employees VALUES (3, 'Kid', 'Young', 15, 2000);
-- INVALID: salary <= 0
-- INSERT INTO employees VALUES (4, 'Alex', 'Poor', 25, 0);

-- Task 1.2
CREATE TABLE products_catalog (
    product_id INT,
    product_name TEXT,
    regular_price NUMERIC,
    discount_price NUMERIC,
    CONSTRAINT valid_discount CHECK (
        regular_price > 0
        AND discount_price > 0
        AND discount_price < regular_price
    )
);

INSERT INTO products_catalog VALUES (1, 'Phone', 1000, 800);
INSERT INTO products_catalog VALUES (2, 'Laptop', 2000, 1500);
-- INVALID: discount >= regular_price
-- INSERT INTO products_catalog VALUES (3, 'TV', 1000, 1200);

-- Task 1.3
CREATE TABLE bookings (
    booking_id INT,
    check_in_date DATE,
    check_out_date DATE,
    num_guests INT CHECK (num_guests BETWEEN 1 AND 10),
    CHECK (check_out_date > check_in_date)
);

INSERT INTO bookings VALUES (1, '2025-10-10', '2025-10-15', 2);
INSERT INTO bookings VALUES (2, '2025-11-01', '2025-11-05', 5);
-- INVALID: check_out_date <= check_in_date
-- INSERT INTO bookings VALUES (3, '2025-11-05', '2025-11-01', 2);

-------------------------------------------------------------------
-- PART 2

CREATE TABLE customers (
    customer_id INT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

INSERT INTO customers VALUES (1, 'john@mail.com', '12345', '2025-10-01');
INSERT INTO customers VALUES (2, 'jane@mail.com', NULL, '2025-10-02');
-- INVALID: missing NOT NULL value
-- INSERT INTO customers VALUES (3, NULL, '54321', '2025-10-03');

CREATE TABLE inventory (
    item_id INT NOT NULL,
    item_name TEXT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    unit_price NUMERIC NOT NULL CHECK (unit_price > 0),
    last_updated TIMESTAMP NOT NULL
);

INSERT INTO inventory VALUES (1, 'Keyboard', 10, 50, NOW());
INSERT INTO inventory VALUES (2, 'Mouse', 25, 30, NOW());
-- INVALID: quantity < 0
-- INSERT INTO inventory VALUES (3, 'BrokenItem', -5, 10, NOW());

-- =====================
-- PART 3: UNIQUE Constraints
-- =====================

CREATE TABLE users (
    user_id INT,
    username TEXT UNIQUE,
    email TEXT UNIQUE,
    created_at TIMESTAMP
);

INSERT INTO users VALUES (1, 'user1', 'user1@mail.com', NOW());
INSERT INTO users VALUES (2, 'user2', 'user2@mail.com', NOW());
-- INVALID: duplicate email
-- INSERT INTO users VALUES (3, 'user3', 'user1@mail.com', NOW());

CREATE TABLE course_enrollments (
    enrollment_id INT,
    student_id INT,
    course_code TEXT,
    semester TEXT,
    CONSTRAINT unique_enrollment UNIQUE (student_id, course_code, semester)
);

INSERT INTO course_enrollments VALUES (1, 1001, 'CS101', 'Fall2025');
INSERT INTO course_enrollments VALUES (2, 1001, 'CS102', 'Fall2025');
-- INVALID: duplicate combo
-- INSERT INTO course_enrollments VALUES (3, 1001, 'CS101', 'Fall2025');

ALTER TABLE users
    ADD CONSTRAINT unique_username UNIQUE (username),
    ADD CONSTRAINT unique_email UNIQUE (email);

-------------------------------------------------------------------
-- PART 4

CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name TEXT NOT NULL,
    location TEXT
);

INSERT INTO departments VALUES (1, 'HR', 'Astana');
INSERT INTO departments VALUES (2, 'IT', 'Almaty');
INSERT INTO departments VALUES (3, 'Finance', 'Shymkent');
-- INVALID: duplicate id
-- INSERT INTO departments VALUES (1, 'Duplicate', 'Test');
-- INVALID: NULL id
-- INSERT INTO departments VALUES (NULL, 'NullDept', 'Test');

CREATE TABLE student_courses (
    student_id INT,
    course_id INT,
    enrollment_date DATE,
    grade TEXT,
    PRIMARY KEY (student_id, course_id)
);

-------------------------------------------------------------------
-- PART 5

CREATE TABLE employees_dept (
    emp_id INT PRIMARY KEY,
    emp_name TEXT NOT NULL,
    dept_id INT REFERENCES departments(dept_id),
    hire_date DATE
);

INSERT INTO employees_dept VALUES (1, 'Ali', 1, '2025-09-01');
-- INVALID: non-existent dept_id
-- INSERT INTO employees_dept VALUES (2, 'Sara', 99, '2025-09-01');

CREATE TABLE authors (
    author_id INT PRIMARY KEY,
    author_name TEXT NOT NULL,
    country TEXT
);

CREATE TABLE publishers (
    publisher_id INT PRIMARY KEY,
    publisher_name TEXT NOT NULL,
    city TEXT
);

CREATE TABLE books (
    book_id INT PRIMARY KEY,
    title TEXT NOT NULL,
    author_id INT REFERENCES authors,
    publisher_id INT REFERENCES publishers,
    publication_year INT,
    isbn TEXT UNIQUE
);

INSERT INTO authors VALUES (1, 'J.K. Rowling', 'UK');
INSERT INTO publishers VALUES (1, 'Bloomsbury', 'London');
INSERT INTO books VALUES (1, 'Harry Potter', 1, 1, 1997, '9780747532743');

CREATE TABLE categories (
    category_id INT PRIMARY KEY,
    category_name TEXT NOT NULL
);

CREATE TABLE products_fk (
    product_id INT PRIMARY KEY,
    product_name TEXT NOT NULL,
    category_id INT REFERENCES categories(category_id) ON DELETE RESTRICT
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY,
    order_date DATE NOT NULL
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY,
    order_id INT REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES products_fk(product_id),
    quantity INT CHECK (quantity > 0)
);

-------------------------------------------------------------------
-- PART 6

CREATE TABLE ecommerce_customers (
    customer_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    phone TEXT,
    registration_date DATE NOT NULL
);

CREATE TABLE ecommerce_products (
    product_id INT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT,
    price NUMERIC CHECK (price >= 0),
    stock_quantity INT CHECK (stock_quantity >= 0)
);

CREATE TABLE ecommerce_orders (
    order_id INT PRIMARY KEY,
    customer_id INT REFERENCES ecommerce_customers(customer_id) ON DELETE CASCADE,
    order_date DATE NOT NULL,
    total_amount NUMERIC CHECK (total_amount >= 0),
    status TEXT CHECK (status IN ('pending','processing','shipped','delivered','cancelled'))
);

CREATE TABLE ecommerce_order_details (
    order_detail_id INT PRIMARY KEY,
    order_id INT REFERENCES ecommerce_orders(order_id) ON DELETE CASCADE,
    product_id INT REFERENCES ecommerce_products(product_id),
    quantity INT CHECK (quantity > 0),
    unit_price NUMERIC CHECK (unit_price >= 0)
);

-- Sample Data
INSERT INTO ecommerce_customers VALUES (1, 'John Smith', 'john@example.com', '12345', '2025-01-01');
INSERT INTO ecommerce_customers VALUES (2, 'Jane Doe', 'jane@example.com', '67890', '2025-02-01');

INSERT INTO ecommerce_products VALUES (1, 'Laptop', 'High-end laptop', 1500, 10);
INSERT INTO ecommerce_products VALUES (2, 'Mouse', 'Wireless mouse', 30, 100);

INSERT INTO ecommerce_orders VALUES (1, 1, '2025-03-01', 1530, 'processing');
INSERT INTO ecommerce_orders VALUES (2, 2, '2025-03-02', 60, 'pending');

INSERT INTO ecommerce_order_details VALUES (1, 1, 1, 1, 1500);
INSERT INTO ecommerce_order_details VALUES (2, 1, 2, 1, 30);
INSERT INTO ecommerce_order_details VALUES (3, 2, 2, 2, 30);

-- INVALID: negative price
-- INSERT INTO ecommerce_products VALUES (3, 'Invalid', 'Negative test', -10, 5);

-- INVALID: wrong status
-- INSERT INTO ecommerce_orders VALUES (3, 1, '2025-04-01', 100, 'unknown');
