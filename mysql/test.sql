-- OUTER关键字详解
-- =====================================

/*
OUTER关键字的作用：
1. 用于SQL语句中的连接（JOIN）操作
2. 指定连接类型为外连接（OUTER JOIN）
3. 外连接会返回左表或右表（或两者）中所有的记录，即使在另一张表中没有匹配项
*/

-- OUTER JOIN 的三种类型：
-- =====================================

-- 1. LEFT OUTER JOIN（左外连接）
-- 返回左表中的所有记录，即使右表中没有匹配项
SELECT a.*, b.*
FROM tableA a
LEFT OUTER JOIN tableB b ON a.id = b.a_id;

-- 等价写法（OUTER可省略）
SELECT a.*, b.*
FROM tableA a
LEFT JOIN tableB b ON a.id = b.a_id;

-- 2. RIGHT OUTER JOIN（右外连接）
-- 返回右表中的所有记录，即使左表中没有匹配项
SELECT a.*, b.*
FROM tableA a
RIGHT OUTER JOIN tableB b ON a.id = b.a_id;

-- 等价写法（OUTER可省略）
SELECT a.*, b.*
FROM tableA a
RIGHT JOIN tableB b ON a.id = b.a_id;

-- 3. FULL OUTER JOIN（全外连接）
-- 返回两张表中的所有记录，无论是否有匹配项
-- 注意：MySQL不直接支持FULL OUTER JOIN，需要用UNION模拟
SELECT a.*, b.*
FROM tableA a
LEFT OUTER JOIN tableB b ON a.id = b.a_id
UNION
SELECT a.*, b.*
FROM tableA a
RIGHT OUTER JOIN tableB b ON a.id = b.a_id;

-- 实际应用示例：
-- =====================================

-- 创建测试表
CREATE TABLE users (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE torders (
    id INT PRIMARY KEY,
    user_id INT,
    product VARCHAR(50)
);

-- 插入测试数据
INSERT INTO users VALUES
(1, '张三'),
(2, '李四'),
(3, '王五');

INSERT INTO torders VALUES
(1, 1, '手机'),
(2, 1, '电脑'),
(3, 2, '平板');

-- LEFT OUTER JOIN 示例
-- 查询所有用户及其订单信息（包括没有订单的用户）
SELECT u.name, o.product
FROM users u
LEFT OUTER JOIN orders o ON u.id = o.user_id;

/*
结果：
张三    手机
张三    电脑
李四    平板
王五    NULL  -- 王五没有订单，但仍然显示
*/

-- RIGHT OUTER JOIN 示例
-- 查询所有订单及其用户信息（包括无效用户的订单）
SELECT u.name, o.product
FROM users u
RIGHT OUTER JOIN orders o ON u.id = o.user_id;

-- 重要注意事项：
-- =====================================

/*
1. OUTER关键字是可选的
   - LEFT OUTER JOIN = LEFT JOIN
   - RIGHT OUTER JOIN = RIGHT JOIN
   - FULL OUTER JOIN = FULL JOIN

2. OUTER不能单独使用
   - 错误：SELECT * FROM table1 OUTER table2
   - 正确：SELECT * FROM table1 LEFT OUTER JOIN table2

3. MySQL特殊性
   - MySQL不支持 FULL OUTER JOIN
   - 需要使用 LEFT JOIN + RIGHT JOIN + UNION 来模拟

4. 性能考虑
   - 外连接通常比内连接性能低
   - 确保连接字段有索引
   - 避免不必要的外连接
*/

-- 常见错误示例：
-- =====================================

-- 错误1：单独使用OUTER
-- SELECT * FROM users OUTER orders;  -- 语法错误

-- 错误2：语法不完整
-- SELECT * FROM users LEFT orders;   -- 缺少JOIN关键字

-- 错误3：MySQL中使用FULL OUTER JOIN
-- SELECT * FROM users FULL OUTER JOIN orders;  -- MySQL不支持

-- 最佳实践：
-- =====================================

/*
1. 明确需求：确定是否真的需要外连接
2. 使用简化语法：LEFT JOIN 而不是 LEFT OUTER JOIN
3. 添加适当的WHERE条件过滤NULL值
4. 为连接字段创建索引
5. 在大表连接时考虑性能影响
*/

-- 示例：过滤NULL值的外连接
SELECT u.name, COALESCE(o.product, '无订单') as product
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;

