# Sales & Inventory Management System (Retail Store)
create database project;
use project;
CREATE TABLE Products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(100),
    category VARCHAR(50),
    price DECIMAL(10,2),
    stock_quantity INT
);
INSERT INTO Products (product_id, product_name, category, price, stock_quantity) VALUES
(1, 'Laptop', 'Electronics', 55000.00, 20),
(2, 'Smartphone', 'Electronics', 25000.00, 50),
(3, 'Headphones', 'Accessories', 1500.00, 100),
(4, 'Office Chair', 'Furniture', 7000.00, 15),
(5, 'Notebook', 'Stationery', 50.00, 200);

CREATE TABLE Customers (
    customer_id INT PRIMARY KEY,
    name VARCHAR(100),
    email VARCHAR(100),
    city VARCHAR(50),
    join_date DATE
);
INSERT INTO Customers (customer_id, name, email, city, join_date) VALUES
(101, 'Anjali Sharma', 'anjali@gmail.com', 'Delhi', '2024-01-15'),
(102, 'Ravi Kumar', 'ravi@gmail.com', 'Mumbai', '2024-03-12'),
(103, 'Neha Verma', 'neha@gmail.com', 'Bangalore', '2024-02-05'),
(104, 'Amit Singh', 'amit@gmail.com', 'Kolkata', '2024-05-20');

CREATE TABLE Sales (
    sale_id INT PRIMARY KEY,
    product_id INT,
    customer_id INT,
    sale_date DATE,
    quantity INT,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
);
INSERT INTO Sales (sale_id, product_id, customer_id, sale_date, quantity) VALUES
(1001, 1, 101, '2024-06-01', 1),
(1002, 2, 102, '2024-06-03', 2),
(1003, 3, 103, '2024-06-05', 3),
(1004, 4, 104, '2024-06-10', 1),
(1005, 5, 101, '2024-06-15', 10),
(1006, 2, 103, '2024-07-01', 1),
(1007, 3, 101, '2024-07-05', 5),
(1008, 1, 104, '2024-07-10', 1),
(1009, 5, 102, '2024-07-11', 20);

select * from products;
select * from Customers;
select * from Sales;

# 🔍Top 5 Selling Products:

SELECT 
    p.product_name, SUM(s.quantity) AS total_sold
FROM
    Sales s
        JOIN
    Products p ON s.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_sold DESC
LIMIT 5;

#📈 Monthly Revenue:

SELECT 
    DATE_FORMAT(sale_date, '%Y-%m') AS month,
    SUM(p.price * s.quantity) AS revenue
FROM
    Sales s
        JOIN
    Products p ON s.product_id = p.product_id
GROUP BY month
ORDER BY month;

#🔔Products with Low Stock:

SELECT 
    product_name, stock_quantity
FROM
    Products
WHERE
    stock_quantity < 10;

#👤Customer Purchase History:

SELECT 
    c.name, p.product_name, s.quantity, s.sale_date
FROM
    Sales s
        JOIN
    Customers c ON s.customer_id = c.customer_id
        JOIN
    Products p ON s.product_id = p.product_id
ORDER BY c.name , s.sale_date;

#💰Total Profit Earned:
# Assume cost price is 70% of selling price

SELECT 
    SUM((p.price - (p.price * 0.7)) * s.quantity) AS profit
FROM
    Sales s
        JOIN
    Products p ON s.product_id = p.product_id;

#🧾Invoices Table:
# Har sale ke sath ek invoice number hona chahiye, taaki billing aur reporting proper ho
CREATE TABLE Invoices (
    invoice_id INT PRIMARY KEY,
    sale_id INT,
    invoice_date DATE,
    total_amount DECIMAL(10,2),
    FOREIGN KEY (sale_id) REFERENCES Sales(sale_id)
);
INSERT INTO Invoices (invoice_id, sale_id, invoice_date, total_amount) VALUES
(501, 1001, '2024-06-01', 55000.00),
(502, 1002, '2024-06-03', 50000.00),
(503, 1003, '2024-06-05', 4500.00),
(504, 1004, '2024-06-10', 7000.00),
(505, 1005, '2024-06-15', 500.00),
(506, 1006, '2024-07-01', 25000.00),
(507, 1007, '2024-07-05', 7500.00),
(508, 1008, '2024-07-10', 55000.00),
(509, 1009, '2024-07-11', 1000.00);

# 📦Suppliers Table:
#Products kis supplier se aate hain — ye information bhi store honi chahiye.
CREATE TABLE Suppliers (
    supplier_id INT PRIMARY KEY,
    supplier_name VARCHAR(100),
    contact_email VARCHAR(100)
);
INSERT INTO Suppliers (supplier_id, supplier_name, contact_email) VALUES
(1, 'Tech World Ltd.', 'contact@techworld.com'),
(2, 'Office Essentials Co.', 'sales@officeessentials.com'),
(3, 'Stationery Hub', 'info@stationeryhub.com');
#🔗 ProductSupplier Table (Many-to-Many Relation);
CREATE TABLE ProductSupplier (
    product_id INT,
    supplier_id INT,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id)
);
INSERT INTO ProductSupplier (product_id, supplier_id) VALUES
(1, 1),
(2, 1),
(3, 1),
(4, 2),
(5, 3);

select * from Invoices;
select * from Suppliers;
select * from ProductSupplier;

#✅ Top Customers by Spending
SELECT 
    c.name, SUM(i.total_amount) AS total_spent
FROM
    Invoices i
        JOIN
    Sales s ON i.sale_id = s.sale_id
        JOIN
    Customers c ON s.customer_id = c.customer_id
GROUP BY c.name
ORDER BY total_spent DESC
LIMIT 5;

#✅ Supplier-wise Product List
SELECT 
    sp.supplier_name, p.product_name
FROM
    ProductSupplier ps
        JOIN
    Suppliers sp ON ps.supplier_id = sp.supplier_id
        JOIN
    Products p ON ps.product_id = p.product_id
ORDER BY sp.supplier_name;

#✅ Daily Sales Summary
SELECT 
    sale_date,
    COUNT(*) AS total_sales,
    SUM(p.price * s.quantity) AS revenue
FROM
    Sales s
        JOIN
    Products p ON s.product_id = p.product_id
GROUP BY sale_date
ORDER BY sale_date DESC;




