# 数据库索引全面指南（含实践用例）

> 目标：系统掌握索引的原理、设计、诊断与优化方法，并能通过可复现实验验证效果。
> 适用：以 MySQL/InnoDB 为主，其他关系型数据库可类比理解。

---

## 1. 索引是什么

索引（Index）是数据库中的一种数据结构，用来加速数据检索。
你可以把它理解为书的目录：目录本身占空间，但能让你快速定位内容。

**核心权衡：**

- 优点：显著提升查询性能（尤其是大表）
- 代价：占用存储空间；写入时需要维护索引，增加 `INSERT/UPDATE/DELETE` 成本

一句话总结：**索引用写入成本和空间，换读取速度。**

---

## 2. 为什么索引快（底层原理）

多数关系型数据库默认使用 **B+Tree** 作为通用索引结构。

### 2.1 B+Tree 的关键特性

- 树高度低，查找复杂度接近 `O(logN)`
- 叶子节点有序，天然支持范围查询和排序
- 磁盘 IO 次数少，适合海量数据检索

### 2.2 常见索引结构对比

| 结构 | 适用场景 | 优势 | 局限 |
| --- | --- | --- | --- |
| B+Tree | 等值、范围、排序、分组 | 通用性最强 | 写入维护成本较高 |
| Hash | 精确等值查询 | 等值检索快 | 不支持范围/排序 |
| FullText | 文本关键词检索 | 自然语言搜索 | 不适合普通过滤条件 |

### 2.3 索引的数据结构（展开）

#### BST（二叉搜索树）

- 左子树节点值小于根，右子树节点值大于根
- 理想情况下查找复杂度为 `O(logN)`，但树退化时会变成 `O(N)`
- 实现简单，适合内存中的基础有序检索教学场景
- 对持续插入有序数据不友好，容易形成“链表化”结构

#### 红黑树（Red-Black Tree）

- 一种自平衡二叉搜索树，通过颜色规则与旋转保持近似平衡
- 查找、插入、删除的时间复杂度稳定在 `O(logN)`
- 单次更新调整成本低于严格平衡树，工程实现较常见
- 由于树高仍相对较高、每节点分支少，在磁盘场景下 IO 次数通常不如 B+Tree

#### B+Tree（主流通用索引）

- 非叶子节点只存键值与子指针，叶子节点存索引键（以及主键/行指针）
- 叶子节点通常按链表有序连接，便于范围扫描和排序扫描
- 树高度较低，适合磁盘页访问，减少随机 IO
- 在 InnoDB 中，主键索引是聚簇索引，二级索引叶子节点保存主键值

#### 为什么数据库索引更偏向 B+Tree（对比 BST/红黑树）

- B+Tree 的一个节点可容纳大量键值（多叉），整体树高更低
- 同样数据规模下，B+Tree 访问层数更少，磁盘随机 IO 更少
- 叶子节点天然有序并串联，范围扫描和排序场景优势明显
- BST/红黑树更适合内存结构；数据库索引主要优化的是磁盘页访问成本

#### BST / RBT / B+Tree 特点总结

| 结构 | 是否自平衡 | 单次查找复杂度 | 范围查询能力 | 树高控制 | 磁盘 IO 友好度 | 典型应用 |
| --- | --- | --- | --- | --- | --- | --- |
| BST | 否（普通实现） | 平均 `O(logN)`，最坏 `O(N)` | 中（有序但易退化） | 弱 | 低 | 教学、内存有序集合 |
| RBT | 是 | `O(logN)` | 中 | 中 | 中 | 语言运行时容器、内存索引 |
| B+Tree | 是（多路平衡） | `O(logN)` | 强（叶子链表天然有序） | 强 | 高 | 数据库主流索引 |

快速记忆：

- **BST**：实现简单，但不平衡时性能波动大
- **RBT**：通过旋转保持平衡，适合内存结构的通用有序集合
- **B+Tree**：多叉、矮胖、顺序访问强，是数据库磁盘索引首选

#### Hash（哈希索引）

- 基于哈希函数计算桶位置，等值匹配速度快
- 典型只支持 `=`、`IN`，不擅长范围查询与排序
- 存在哈希冲突，需要额外处理冲突链/桶
- 更适合内存场景或特定存储引擎实现

#### FullText（全文索引）

- 通过分词、倒排索引组织文本数据
- 适合“关键词检索”而不是普通结构化过滤
- 常与相关性打分结合（如按匹配度排序）
- 对中文通常需要关注分词器质量与词典配置

#### Bitmap（位图索引，部分数据库常见）

- 将列值映射为位向量，低基数列压缩效果好
- 在分析型查询中对多条件组合过滤效率高
- 不适合高并发、高频更新场景（位图维护成本高）

### 2.4 索引的优缺点（展开）

#### 优点

- 显著降低查询扫描行数，提升 `SELECT` 性能
- 对 `WHERE`、`JOIN`、`ORDER BY`、`GROUP BY` 常有明显加速
- 覆盖索引可减少回表，降低 IO 与延迟
- 唯一索引可辅助保障数据一致性

#### 缺点

- 增加磁盘与内存占用（索引页需要存储和缓存）
- 降低写入性能（写操作需要维护多个索引）
- 索引越多，优化器决策越复杂，可能出现次优执行计划
- 冗余或低质量索引会增加维护成本且收益有限

#### 适用边界建议

- 读多写少系统可更积极建索引
- 写多读少系统应严格控制索引数量
- 低区分度列通常不单独建索引，可考虑联合索引中的非首列
- 索引设计要以真实慢 SQL 和 `EXPLAIN` 结果为准

---

## 3. 索引类型（高频知识点）

### 3.1 按约束能力

- **主键索引（PRIMARY KEY）**：唯一且非空
- **唯一索引（UNIQUE）**：值必须唯一
- **普通索引（INDEX）**：仅用于加速查询

### 3.2 按列数量

- **单列索引**
- **联合索引（复合索引）**：多个列组成，实战中最常用

### 3.3 InnoDB 的物理组织

- **聚簇索引（Clustered Index）**：主键索引叶子节点就是整行数据
- **二级索引（Secondary Index）**：叶子节点存主键值，查完整行通常需要“回表”

---

## 4. 联合索引与最左前缀原则

假设有联合索引：`(a, b, c)`。

### 4.1 能高效利用索引的条件

- `a = ?`
- `a = ? AND b = ?`
- `a = ? AND b = ? AND c = ?`
- `a = ? AND b > ?`（可用到 `b`，但后续列能力通常下降）

### 4.2 容易失效或效果差的条件

- `b = ?`（跳过最左列）
- `c = ?`
- `a LIKE '%xx'`（前导通配符）

口诀：**从左到右，遇到范围，后面打折。**

---

## 5. 覆盖索引与回表

### 5.1 覆盖索引

查询字段全部包含在索引中，数据库可直接返回结果，不必回表。

### 5.2 回表

先通过二级索引找到主键，再去聚簇索引取完整数据。
当回表次数多时，性能下降明显。

### 5.3 实用建议

- 避免 `SELECT *`
- 高频查询优先设计“过滤列 + 返回列”联合索引

---

## 6. 索引对排序与分组的帮助

当 `ORDER BY` / `GROUP BY` 与索引顺序匹配时，数据库可利用索引有序性，减少排序或临时表开销。

例如索引 `(status, created_at)` 对这类语句通常友好：

```sql
SELECT id, status, created_at
FROM orders
WHERE status = 1
ORDER BY created_at DESC
LIMIT 20;
```

---

## 7. 什么时候该建索引

### 建议建索引的列

- 高频出现在 `WHERE`、`JOIN`、`ORDER BY`、`GROUP BY`
- 区分度高（选择性好）的列
- 关联键（如用户 ID、订单号）

### 谨慎建索引的列

- 低区分度列（如性别、布尔状态，单独索引意义小）
- 更新非常频繁的列
- 小表（全表扫描本就便宜）

---

## 8. 常见索引失效原因

- 在索引列上使用函数或表达式（如 `DATE(create_time)`）
- 隐式类型转换（字符串列与数字直接比较）
- 前导 `%` 的模糊匹配（`LIKE '%abc'`）
- 联合索引不满足最左前缀
- `OR` 条件中部分列无索引，导致优化器放弃索引
- 统计信息不准确，执行计划误判

---

## 9. 索引设计方法论（推荐流程）

1. 从慢 SQL 入手，而不是先拍脑袋建索引
2. 明确查询模式：等值、范围、排序、分页、返回列
3. 按“过滤能力 + 排序需求 + 覆盖需求”设计联合索引
4. 用 `EXPLAIN` 验证是否命中索引
5. 观察写入影响，清理冗余和重复索引

---

## 10. 实践用例（可直接执行）

> 下面用一组完整 SQL 演示：无索引慢、合理索引快、错误写法导致失效。

### 10.1 创建测试表与样例数据

```sql
DROP TABLE IF EXISTS users;
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  email VARCHAR(100) NOT NULL,
  name VARCHAR(50) NOT NULL,
  status TINYINT NOT NULL,
  age INT NOT NULL,
  city VARCHAR(50) NOT NULL,
  created_at DATETIME NOT NULL,
  updated_at DATETIME NOT NULL
) ENGINE=InnoDB;

-- 建议插入 10 万+ 数据用于观察差异
-- 此处给出少量示例
INSERT INTO users (email, name, status, age, city, created_at, updated_at) VALUES
('a01@example.com', 'Alice', 1, 23, 'Beijing', '2026-01-01 10:00:00', NOW()),
('b02@example.com', 'Bob',   1, 29, 'Shanghai','2026-01-03 12:00:00', NOW()),
('c03@example.com', 'Cindy', 0, 31, 'Shenzhen','2026-01-04 09:00:00', NOW()),
('d04@example.com', 'David', 1, 35, 'Hangzhou','2026-01-05 18:00:00', NOW());
```

---

### 10.2 场景 A：等值查询优化

#### 1) 无索引查询

```sql
EXPLAIN SELECT * FROM users WHERE email = 'b02@example.com';
```

预期：可能看到 `type = ALL`（全表扫描）。

#### 2) 添加唯一索引

```sql
CREATE UNIQUE INDEX idx_users_email ON users(email);
EXPLAIN SELECT * FROM users WHERE email = 'b02@example.com';
```

预期：`type` 变为 `const` / `ref`，扫描行数明显下降。

---

### 10.3 场景 B：联合索引 + 排序优化

目标 SQL：

```sql
EXPLAIN
SELECT id, status, created_at
FROM users
WHERE status = 1
ORDER BY created_at DESC
LIMIT 20;
```

添加索引：

```sql
CREATE INDEX idx_users_status_created_at ON users(status, created_at);
```

预期收益：

- `WHERE status = 1` 过滤更快
- 排序可借助索引顺序，减少 filesort 风险

---

### 10.4 场景 C：覆盖索引减少回表

目标 SQL（只查索引中包含的列）：

```sql
EXPLAIN
SELECT status, created_at
FROM users
WHERE status = 1
AND created_at >= '2026-01-01'
ORDER BY created_at DESC
LIMIT 20;
```

若使用 `(status, created_at)`，该查询大概率可形成覆盖索引访问（具体以执行计划为准）。

---

### 10.5 场景 D：错误写法导致索引失效

#### 反例 1：在索引列上使用函数

```sql
-- 即使 created_at 有索引，函数处理后通常无法走索引
EXPLAIN
SELECT id
FROM users
WHERE DATE(created_at) = '2026-01-03';
```

改写为范围查询：

```sql
EXPLAIN
SELECT id
FROM users
WHERE created_at >= '2026-01-03 00:00:00'
  AND created_at <  '2026-01-04 00:00:00';
```

#### 反例 2：前导通配符

```sql
-- 常见失效
EXPLAIN SELECT id FROM users WHERE email LIKE '%@example.com';
```

可优化方向：

- 改为后缀固定前缀匹配（若业务允许），如 `LIKE 'b02%'`
- 或引入全文索引 / 搜索引擎（按业务需求）

---

## 11. EXPLAIN 重点字段解读

| 字段 | 含义 | 关注点 |
| --- | --- | --- |
| type | 访问类型 | 至少达到 `range/ref`，避免 `ALL` |
| key | 实际使用索引 | 是否命中预期索引 |
| rows | 预估扫描行数 | 越小通常越好 |
| Extra | 额外信息 | 注意 `Using filesort`、`Using temporary` |

---

## 12. 索引优化 Checklist（落地版）

- 是否真的存在慢 SQL（先观测再优化）
- 当前 SQL 是否能满足最左前缀
- 是否存在函数计算、隐式转换、前导 `%`
- 是否能通过覆盖索引减少回表
- 是否出现冗余索引（如 `(a,b)` 与 `(a)` 重复）
- 索引收益是否大于写入代价

---

## 13. 常见面试题速答

### Q1：为什么不建议建太多索引？

因为每个索引都会占用空间，并在写操作时维护，导致写入变慢。

### Q2：联合索引 `(a,b,c)` 对 `b,c` 有用吗？

单独 `b` 或 `c` 通常无法高效利用该索引（不满足最左前缀）。

### Q3：`SELECT *` 为什么不利于性能？

更容易触发回表与额外 IO，难以利用覆盖索引。

---

## 14. 一页总结

- 索引是数据库性能优化的核心手段之一
- 联合索引设计能力决定了多数查询性能上限
- 牢记三件事：**最左前缀、覆盖索引、避免失效**
- 任何优化都要用 `EXPLAIN` 与真实数据量验证

---

## 附录 A. 索引相关语法速查（MySQL）

> 说明：不同数据库（PostgreSQL/Oracle/SQL Server）语法略有差异，以下以 MySQL 为主。

### A.1 创建索引

```sql
-- 1) 普通单列索引
CREATE INDEX idx_users_city ON users(city);

-- 2) 唯一索引
CREATE UNIQUE INDEX idx_users_email ON users(email);

-- 3) 联合索引（复合索引）
CREATE INDEX idx_users_status_created_at ON users(status, created_at);

-- 4) 前缀索引（字符串列常用，节省空间）
CREATE INDEX idx_users_name_prefix ON users(name(10));

-- 5) 通过 ALTER TABLE 添加索引
ALTER TABLE users ADD INDEX idx_users_age (age);
ALTER TABLE users ADD UNIQUE INDEX idx_users_email_uq (email);
```

### A.2 删除索引

```sql
-- 1) 通过 DROP INDEX 删除二级索引
DROP INDEX idx_users_city ON users;

-- 2) 通过 ALTER TABLE 删除索引
ALTER TABLE users DROP INDEX idx_users_age;
```

### A.3 查看索引

```sql
-- 查看某张表的索引信息
SHOW INDEX FROM users;

-- 查看建表语句（可看到主键、唯一约束、索引定义）
SHOW CREATE TABLE users;
```

### A.4 主键相关语法

```sql
-- 添加主键
ALTER TABLE users ADD PRIMARY KEY (id);

-- 删除主键（谨慎操作，可能影响业务和外键依赖）
ALTER TABLE users DROP PRIMARY KEY;
```

### A.5 重命名索引（MySQL 5.7+）

```sql
ALTER TABLE users RENAME INDEX idx_users_status_created_at TO idx_users_status_ctime;
```

### A.6 索引与约束的常见写法（建表时）

```sql
CREATE TABLE orders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  order_no VARCHAR(64) NOT NULL,
  user_id BIGINT NOT NULL,
  status TINYINT NOT NULL,
  created_at DATETIME NOT NULL,
  UNIQUE KEY uk_orders_order_no (order_no),
  KEY idx_orders_user_created (user_id, created_at),
  KEY idx_orders_status (status)
) ENGINE=InnoDB;
```

### A.7 执行计划语法（索引是否命中）

```sql
-- 传统执行计划
EXPLAIN
SELECT id, user_id, created_at
FROM orders
WHERE user_id = 10001
ORDER BY created_at DESC
LIMIT 20;

-- MySQL 8 可使用 ANALYZE 观察实际执行信息
EXPLAIN ANALYZE
SELECT id, user_id, created_at
FROM orders
WHERE user_id = 10001
ORDER BY created_at DESC
LIMIT 20;
```

### A.8 使用注意事项

- 建联合索引时优先考虑高频过滤列与排序列顺序
- 不要重复创建冗余索引（如已有 `(a,b)` 后再建 `(a)` 需结合场景评估）
- 大表加索引建议在低峰期执行，并评估锁影响
- 变更前后都要用 `EXPLAIN` 对比验证收益

如果你后续希望继续完善，我可以在这个文档基础上追加：

- MySQL 8 `EXPLAIN ANALYZE` 实战
- 线上慢查询定位脚本
- “索引设计题”专项练习（含答案）
