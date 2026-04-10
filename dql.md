# DQL（数据查询语言）要点总结

DQL 是 Data Query Language 的缩写，主要用于查询数据库中的数据。它是 SQL 中最常用的查询部分，以 `SELECT` 语句为核心。

## 1. DQL 的核心语句

- 主要语句：`SELECT`
- 目标：从一个或多个表中读取数据，而不直接修改表数据结构或内容。
- 结果：返回结果集，可结合聚合、排序、分组、分页等操作。

## 2. SELECT 基本结构

```sql
SELECT [DISTINCT] 列1, 列2, ...
FROM 表名
[WHERE 条件]
[GROUP BY 列]
[HAVING 条件]
[ORDER BY 列 [ASC|DESC]]
[LIMIT 数量 [OFFSET 偏移]];
```

### 关键组成部分
- `SELECT`：指定查询列，可以使用表达式、函数、别名。
- `FROM`：指定来源表或视图，也可使用子查询。
- `WHERE`：行级过滤条件，控制返回记录范围。
- `GROUP BY`：分组聚合，用于计算分组统计值。
- `HAVING`：分组后过滤，用于聚合条件。
- `ORDER BY`：排序结果集。
- `LIMIT` / `OFFSET`：控制分页结果。

## 3. 常见查询模式

### 简单查询
```sql
SELECT id, name FROM users;
```

### 条件过滤
```sql
SELECT * FROM users WHERE age > 18 AND status = 'active';
```

### 模糊查询
```sql
SELECT * FROM users WHERE name LIKE '张%';
```

### 范围查询
```sql
SELECT * FROM orders WHERE order_date BETWEEN '2024-01-01' AND '2024-12-31';
```

### 去重查询
```sql
SELECT DISTINCT department FROM employees;
```

### 聚合查询
```sql
SELECT COUNT(*) AS total, AVG(salary) FROM employees;
```

### 分组查询
```sql
SELECT department, COUNT(*) FROM employees GROUP BY department;
```

### 分组过滤
```sql
SELECT department, COUNT(*) FROM employees
GROUP BY department
HAVING COUNT(*) > 5;
```

### 排序与分页
```sql
SELECT * FROM products ORDER BY price DESC LIMIT 20 OFFSET 0;
```

## 4. 查询条件常用写法（WHERE）

`WHERE` 用于在分组前过滤行，是最常用也最关键的条件子句。

### 比较运算
```sql
SELECT * FROM users WHERE age >= 18;
SELECT * FROM products WHERE price <> 0;
```

### 范围与集合
```sql
SELECT * FROM orders WHERE total BETWEEN 100 AND 500;
SELECT * FROM users WHERE city IN ('上海', '北京', '深圳');
```

### 空值判断
> `NULL` 不能用 `=` 比较，应使用 `IS NULL` / `IS NOT NULL`。

```sql
SELECT * FROM employees WHERE manager_id IS NULL;
SELECT * FROM employees WHERE manager_id IS NOT NULL;
```

### 模糊匹配（LIKE）
- `%`：任意长度任意字符。
- `_`：单个任意字符。

```sql
SELECT * FROM users WHERE name LIKE '张%';
SELECT * FROM users WHERE phone LIKE '138_______';
```

### 逻辑组合
```sql
SELECT * FROM users
WHERE status = 'active'
  AND (age BETWEEN 18 AND 30 OR vip_level >= 3);
```

### 否定条件
```sql
SELECT * FROM products WHERE category NOT IN ('test', 'deprecated');
SELECT * FROM users WHERE name NOT LIKE '%临时%';
```

### 常见建议
- 复杂条件优先加括号，避免 `AND` / `OR` 优先级误判。
- 对高频过滤列建立索引，提高查询效率。
- 能在 `WHERE` 过滤的条件尽量不要放到 `HAVING`。

## 5. 分组查询与聚合函数

分组查询用于“按某个维度汇总数据”，聚合函数用于“对一组数据做统计计算”。

### 常见聚合函数
- `COUNT(*)`：统计行数（包含 `NULL` 行）。
- `COUNT(列名)`：统计该列非 `NULL` 的行数。
- `SUM(列名)`：求和。
- `AVG(列名)`：平均值。
- `MAX(列名)` / `MIN(列名)`：最大值 / 最小值。

```sql
SELECT
  COUNT(*) AS total_orders,
  SUM(total) AS total_amount,
  AVG(total) AS avg_amount,
  MAX(total) AS max_amount,
  MIN(total) AS min_amount
FROM orders;
```

### GROUP BY 基本写法
```sql
SELECT department, COUNT(*) AS emp_count
FROM employees
GROUP BY department;
```

```sql
SELECT IF(gendar = 1, "男性", "女性") AS 性别, COUNT(*) FROM users GROUP BY gendar;
```

```sql
SELECT (CASE gendar WHEN 1 THEN "男性" WHEN 2 THEN "女性" END) AS 性别, COUNT(*) FROM users GROUP BY gendar;
```

### 多列分组
```sql
SELECT department, job_title, COUNT(*) AS cnt
FROM employees
GROUP BY department, job_title;
```

### HAVING 过滤分组结果
- `WHERE`：分组前过滤原始行。
- `HAVING`：分组后过滤聚合结果。

```sql
SELECT department, AVG(salary) AS avg_salary
FROM employees
WHERE status = 'active'
GROUP BY department
HAVING AVG(salary) > 10000;
```

### 条件聚合（常用）
```sql
SELECT
  department,
  COUNT(*) AS total_count,
  SUM(CASE WHEN gender = 'M' THEN 1 ELSE 0 END) AS male_count,
  SUM(CASE WHEN gender = 'F' THEN 1 ELSE 0 END) AS female_count
FROM employees
GROUP BY department;
```

### 常见注意点
- 使用 `GROUP BY` 时，`SELECT` 中非聚合列通常都应出现在分组字段里。
- `COUNT(*)` 与 `COUNT(列名)` 语义不同，注意是否要排除 `NULL`。
- 分组字段建议配合索引，减少排序和临时表开销。

## 6. 排序查询（ORDER BY）

排序用于控制结果集展示顺序，默认升序（`ASC`）。

### 基本排序
```sql
SELECT id, name, salary
FROM employees
ORDER BY salary DESC;
```

### 多字段排序
- 先按前面的字段排序，当前字段相同再按后面的字段排序。

```sql
SELECT id, department, salary, hire_date
FROM employees
ORDER BY department ASC, salary DESC, hire_date ASC;
```

### 按别名或表达式排序
```sql
SELECT name, salary * 12 AS annual_salary
FROM employees
ORDER BY annual_salary DESC;
```

### 与分页结合
```sql
SELECT id, name, price
FROM products
ORDER BY price DESC, id ASC
LIMIT 20 OFFSET 0;
```

### `NULL` 排序处理（MySQL 常用）
- MySQL 中，升序时 `NULL` 通常在前，降序时通常在后。
- 可通过布尔表达式控制 `NULL` 放置位置。

```sql
SELECT id, score
FROM exam_result
ORDER BY score IS NULL ASC, score DESC;
```

### 常见注意点
- 没有 `ORDER BY` 时，结果顺序不保证稳定。
- 分页查询建议加唯一字段作为次排序键（如 `id`），避免翻页重复或漏数据。
- 大表排序开销高，尽量让排序字段命中索引。

## 7. 分页查询（LIMIT / OFFSET）

分页用于分批读取结果，常见于列表页、后台管理页和接口查询。

### 基本写法
```sql
SELECT id, name, price
FROM products
ORDER BY id ASC
LIMIT 10 OFFSET 0;
```

### MySQL 简写
```sql
SELECT id, name
FROM users
ORDER BY id ASC
LIMIT 0, 10; -- 等价于 LIMIT 10 OFFSET 0
```

### 按页码计算偏移量
- 公式：`OFFSET = (page - 1) * page_size`

```sql
-- 第 3 页，每页 20 条
SELECT id, title, created_at
FROM articles
ORDER BY created_at DESC, id DESC
LIMIT 20 OFFSET 40;
```

### 分页总数统计
```sql
SELECT COUNT(*) AS total FROM articles WHERE status = 'published';
```

### 基于游标/主键的翻页（Keyset Pagination）
- 适合大数据量列表，避免大 `OFFSET` 带来的性能下降。
- 核心思路：用“上一页最后一条记录的排序键”作为下一页查询条件。

```sql
-- 第一页
SELECT id, title, created_at
FROM articles
WHERE status = 'published'
ORDER BY id ASC
LIMIT 20;

-- 下一页（last_id 为上一页最后一条 id）
SELECT id, title, created_at
FROM articles
WHERE status = 'published'
  AND id > :last_id
ORDER BY id ASC
LIMIT 20;
```

```sql
-- 按时间倒序 + id 倒序的复合游标（推荐）
-- cursor_created_at / cursor_id 来自上一页最后一条记录
SELECT id, title, created_at
FROM articles
WHERE status = 'published'
  AND (
    created_at < :cursor_created_at
    OR (created_at = :cursor_created_at AND id < :cursor_id)
  )
ORDER BY created_at DESC, id DESC
LIMIT 20;
```

```sql
-- 上一页（反向翻页示例）
SELECT id, title, created_at
FROM articles
WHERE status = 'published'
  AND (
    created_at > :cursor_created_at
    OR (created_at = :cursor_created_at AND id > :cursor_id)
  )
ORDER BY created_at ASC, id ASC
LIMIT 20;
-- 应用层拿到结果后再反转，恢复为 DESC 展示
```

### 常见注意点
- 分页必须配合稳定排序（通常 `ORDER BY 时间 DESC, id DESC`）。
- 仅用 `LIMIT/OFFSET` 不排序时，结果顺序不稳定。
- 深分页（`OFFSET` 很大）性能会下降，可考虑基于游标/主键的翻页。

## 8. 别名（Alias）

别名用于给列、表或子查询结果起一个临时名字，让 SQL 更易读，尤其在多表查询或表达式较多时非常有用。

### 列别名
- 常用于聚合结果、计算列、长字段名简化显示。
- 推荐写法：`AS 别名`（`AS` 可省略，但显式写出可读性更好）。

```sql
SELECT
  name AS user_name,
  salary * 12 AS annual_salary,
  COUNT(*) AS total
FROM employees;
```

### 表别名
- 常用于 `JOIN` 场景，减少重复书写表名。
- 表别名一旦定义，后续引用该表字段通常应使用别名。

```sql
SELECT u.name, o.order_id, o.total
FROM users AS u
INNER JOIN orders AS o ON u.id = o.user_id;
```

### 子查询别名
- 子查询放在 `FROM` 中时，通常必须提供别名（大多数数据库要求）。

```sql
SELECT t.department, t.avg_salary
FROM (
  SELECT department, AVG(salary) AS avg_salary
  FROM employees
  GROUP BY department
) AS t;
```

### 使用注意
- 别名一般可在 `ORDER BY` 中使用。
- 别名通常不能在同一层的 `WHERE` 中直接使用（可改用原表达式，或在外层再包一层查询）。
- 避免使用与关键字冲突的别名；必要时使用反引号，例如 `` `order` ``。

## 9. 多表查询与连接

- `INNER JOIN`：返回两个表中匹配的行。
- `LEFT JOIN` / `RIGHT JOIN`：返回一侧所有行及匹配行。
- `CROSS JOIN`：笛卡尔积查询。
- `SELF JOIN`：表自身连接。

```sql
SELECT u.name, o.order_id FROM users u
INNER JOIN orders o ON u.id = o.user_id;
```

## 10. 子查询与派生表

- 子查询可出现在 `SELECT`、`FROM`、`WHERE`、`HAVING` 中。
- 子查询可用于复杂条件、分组统计、数据驱动过滤。

```sql
SELECT u.name, u.email FROM users u
WHERE u.id IN (SELECT user_id FROM orders WHERE total > 1000);
```

## 11. DQL 性能要点

- 避免 `SELECT *`，只查询需要字段。
- 将过滤条件放在 `WHERE` 子句中，尽可能使用索引列。
- 对排序、分组、JOIN 所用列建立合适索引。
- 使用 `LIMIT` 分页，避免一次查询过多数据。
- 对大型查询考虑分批、物化视图、缓存等策略。

## 12. 常见问题与注意事项

- `WHERE` 条件不生效：注意列名、表别名、逻辑顺序。
- 聚合查询忘记 `GROUP BY`：会导致 MySQL 模式下结果不确定。
- 子查询性能差：必要时改写成 `JOIN` 或使用临时表。
- `ORDER BY` + `LIMIT`：若排序列无索引，可能导致全表排序。

## 13. DQL 与其他 SQL 类型的关系

- DML：用于增删改数据。
- DDL：用于定义数据库结构。
- DCL：用于权限管理。
- TCL：用于事务控制。

> DQL 是数据库查询的核心，熟练掌握 `SELECT` 语法、过滤、聚合、连接与分页是开发与分析查询性能的基础。
