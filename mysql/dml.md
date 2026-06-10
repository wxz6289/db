# DML（数据操纵语言）总结

DML 是 Data Manipulation Language 的缩写，用于对数据库中的数据进行增、删、改、查操作。它是 SQL 中最常用的语句类型。

## 1. SELECT 查询操作

### 基本语法

```sql
SELECT [DISTINCT] 列列表 | *
FROM 表名
[WHERE 条件]
[GROUP BY 列 [HAVING 条件]]
[ORDER BY 列 [ASC|DESC]]
[LIMIT 数量 [OFFSET 偏移]];
```

### 常见查询示例

- **简单查询**：
  ```sql
  SELECT id, name, age FROM users;
  SELECT DISTINCT gender FROM users;  -- 去重
  ```

- **条件查询**：
  ```sql
  SELECT * FROM users WHERE age > 18;
  SELECT * FROM users WHERE name LIKE '张%';
  SELECT * FROM users WHERE id IN (1, 2, 3);
  SELECT * FROM users WHERE age BETWEEN 20 AND 30;
  ```

- **分组聚合**：
  ```sql
  SELECT gender, COUNT(*) as count FROM users GROUP BY gender;
  SELECT department, AVG(salary) FROM employees GROUP BY department;
  SELECT department, AVG(salary) FROM employees GROUP BY department HAVING AVG(salary) > 5000;
  ```

- **排序和分页**：
  ```sql
  SELECT * FROM users ORDER BY age DESC;
  SELECT * FROM users ORDER BY age DESC LIMIT 10 OFFSET 0;  -- 第 1 页
  SELECT * FROM users ORDER BY age DESC LIMIT 10;           -- MySQL 简写
  ```

- **JOIN 多表查询**：
  ```sql
  SELECT u.name, o.order_id FROM users u
  INNER JOIN orders o ON u.id = o.user_id;

  SELECT u.name, o.order_id FROM users u
  LEFT JOIN orders o ON u.id = o.user_id;
  ```

- **聚合函数**：
  ```sql
  SELECT COUNT(*), SUM(salary), AVG(salary), MAX(salary), MIN(salary)
  FROM employees;
  ```

### 查询特性
- `DISTINCT`：去除重复行。
- `WHERE`：行级过滤，在分组前执行。
- `GROUP BY`：分组聚合。
- `HAVING`：组级过滤，在分组后执行。
- `ORDER BY`：排序结果。
- `LIMIT`/`OFFSET`：分页。

## 2. INSERT 插入操作

### 基本语法

```sql
INSERT INTO 表名 [(列1, 列2, ...)]
VALUES (值1, 值2, ...);
```

### 常见插入示例

- **单行插入**：
  ```sql
  INSERT INTO users (id, name, age) VALUES (1, '张三', 25);
  ```

- **多行插入**：
  ```sql
  INSERT INTO users (id, name, age)
  VALUES (1, '张三', 25), (2, '李四', 28), (3, '王五', 30);
  ```

- **从查询结果插入**：
  ```sql
  INSERT INTO users_backup SELECT * FROM users WHERE age > 30;
  ```

- **省略列列表（按表定义顺序）**：
  ```sql
  INSERT INTO users VALUES (1, '张三', 25);
  ```

### 插入特点
- 若列有 `AUTO_INCREMENT`，可省略该列。
- 若列有 `DEFAULT` 值，插入时可省略。
- `NOT NULL` 列必须提供值。
- 违反唯一约束或主键将导致插入失败。

## 3. UPDATE 更新操作

### 基本语法

```sql
UPDATE 表名
SET 列1=值1, 列2=值2, ...
[WHERE 条件]
[ORDER BY 列 [LIMIT 数量]];
```

### 常见更新示例

- **无条件更新（谨慎使用）**：
  ```sql
  UPDATE users SET age = 25;  -- 更新所有行
  ```

- **条件更新**：
  ```sql
  UPDATE users SET age = 30 WHERE id = 1;
  UPDATE users SET status = 'active' WHERE age > 18;
  ```

- **多列更新**：
  ```sql
  UPDATE users SET age = 25, status = 'active' WHERE id = 1;
  ```

- **基于表达式更新**：
  ```sql
  UPDATE employees SET salary = salary * 1.1 WHERE department = 'IT';
  UPDATE users SET update_time = CURRENT_TIMESTAMP WHERE id = 1;
  ```

- **多表更新**：
  ```sql
  UPDATE users u, orders o
  SET u.status = 'VIP'
  WHERE u.id = o.user_id AND o.total > 10000;
  ```

- **限制更新行数**：
  ```sql
  UPDATE users SET age = 25 ORDER BY id LIMIT 5;
  ```

### 更新特点
- 没有 `WHERE` 子句会更新整个表，生产环境需谨慎。
- 更新会触发 `ON UPDATE DEFAULT CURRENT_TIMESTAMP`。
- 违反约束的更新会失败。

## 4. DELETE 删除操作

### 基本语法

```sql
DELETE FROM 表名
[WHERE 条件]
[ORDER BY 列 [LIMIT 数量]];
```

### 常见删除示例

- **无条件删除（谨慎使用）**：
  ```sql
  DELETE FROM users;  -- 删除所有行
  ```

- **条件删除**：
  ```sql
  DELETE FROM users WHERE id = 1;
  DELETE FROM users WHERE age < 18;
  ```

- **限制删除行数**：
  ```sql
  DELETE FROM users ORDER BY id DESC LIMIT 10;
  ```

- **多表删除**：
  ```sql
  DELETE u FROM users u
  WHERE u.id NOT IN (SELECT user_id FROM orders);
  ```

- **删除重复数据**：
  ```sql
  DELETE FROM users
  WHERE id NOT IN (
    SELECT MIN(id) FROM users GROUP BY email
  );
  ```

### 删除特点
- 没有 `WHERE` 子句会删除整个表的所有数据。
- `DELETE` 删除行（快速），`TRUNCATE` 清空表（更快，但不可回滚）。
- 删除存在外键约束的行可能失败。
- 不能删除某一字段的值，只能删除整行数据，若想清空某列的值需使用 `UPDATE` 将该列设置为 `NULL` 或默认值。

## 5. DML 操作的实战要点

### 查询优化
- 避免全表扫描，使用索引列在 `WHERE` 条件中。
- 使用 `LIMIT` 控制返回行数。
- 避免 `SELECT *`，明确指定需要的列。
- 分组时确保分组列有索引。

### 修改操作安全
- **执行前验证**：修改前用 `SELECT` 验证条件范围。
- **使用事务**：
  ```sql
  START TRANSACTION;
  UPDATE users SET age = 25 WHERE id = 1;
  -- 检查结果
  ROLLBACK;  -- 或 COMMIT
  ```
- **避免无条件操作**：总是加上 `WHERE` 条件。
- **大批量操作**：考虑分批处理，避免锁表过长。

### 性能考虑
- 大量插入使用 `LOAD DATA INFILE` 或批量插入。
- 大量删除可考虑先禁用外键再删除：
  ```sql
  SET FOREIGN_KEY_CHECKS = 0;
  DELETE FROM 表;
  SET FOREIGN_KEY_CHECKS = 1;
  ```
- 定期清理过期数据，避免表过大。

### 常见错误
- 忘记 `WHERE` 条件导致全表更新/删除。
- 删除存在外键约束的记录失败。
- `WHERE` 条件中列名拼写错误。
- 更新时使用错误的列名导致数据丢失。

## 6. 事务控制与 DML
- DML 操作通常在事务中执行，保证数据一致性：
  ```sql
  START TRANSACTION;
  INSERT INTO account_from SET balance = balance - 100 WHERE id = 1;
  INSERT INTO account_to SET balance = balance + 100 WHERE id = 2;
  COMMIT;
  ```

> DML 是日常 SQL 操作的核心，合理使用查询和修改操作直接影响数据库性能和数据安全性。
