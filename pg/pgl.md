



# PostgreSQL 教程核心梳理

> 基于 [PostgreSQL 官方教程（部分 I）](http://www.postgres.cn/docs/current/tutorial.html) 整理。  
> 目标：覆盖入门到进阶的核心概念，条理清晰，并附可运行的 SQL 示例。  
> 示例统一使用教程中的 `weather`（天气）与 `cities`（城市）表。

---

## 目录

1. [概述与学习路径](#1-概述与学习路径)
2. [入门：安装与架构](#2-入门安装与架构)
3. [核心概念](#3-核心概念)
4. [数据库与连接](#4-数据库与连接)
5. [DDL：创建与删除表](#5-ddl创建与删除表)
6. [DML：插入数据](#6-dml插入数据)
7. [DQL：查询数据](#7-dql查询数据)
8. [表连接（JOIN）](#8-表连接join)
9. [聚合函数与分组](#9-聚合函数与分组)
10. [更新与删除](#10-更新与删除)
11. [视图（VIEW）](#11-视图view)
12. [外键与引用完整性](#12-外键与引用完整性)
13. [事务](#13-事务)
14. [窗口函数](#14-窗口函数)
15. [表继承](#15-表继承)
16. [速查与最佳实践](#16-速查与最佳实践)
17. [SQL 命令参考（按重要性分级）](#17-sql-命令参考按重要性分级)

---

## 1. 概述与学习路径

PostgreSQL（简称 PG）是一种**关系型数据库管理系统（RDBMS）**，用**表（table）**存储数据，用 **SQL** 进行查询与操作。

官方教程分为三章：


| 章节           | 内容                    |
| ------------ | --------------------- |
| 第 1 章 入门     | 安装、架构、创建数据库、`psql` 使用 |
| 第 2 章 SQL 语言 | 建表、增删改查、连接、聚合         |
| 第 3 章 高级特性   | 视图、外键、事务、窗口函数、继承      |


学完本教程后，建议继续阅读：

- **第 II 部分**：SQL 语言完整参考
- **第 III 部分**：服务器管理与配置
- **第 IV 部分**：客户端编程接口

教程源码与示例脚本位于 PostgreSQL 源码目录 `src/tutorial/`（`basics.sql`、`advanced.sql`）。

---

## 2. 入门：安装与架构

### 2.1 安装

PostgreSQL 可能已随操作系统预装，也可自行安装（无需 root，详见官方第 17 章）。

若客户端连不上服务器，检查环境变量：


| 变量       | 含义          |
| -------- | ----------- |
| `PGHOST` | 数据库服务器主机名   |
| `PGPORT` | 端口（默认 5432） |
| `PGUSER` | 连接用户名       |


### 2.2 客户端/服务器架构

PostgreSQL 采用 **C/S 模型**：

```
┌─────────────┐     TCP/IP 或 Unix Socket     ┌──────────────────┐
│  客户端应用  │ ◄──────────────────────────► │  postgres 守护进程 │
│ (psql/pgAdmin)│                              │  为每个连接 fork   │
└─────────────┘                               │  独立后端进程      │
                                              └──────────────────┘
```

- **服务器进程**（`postgres`）：管理数据文件，接受连接，执行 SQL。
- **客户端**：`psql`、图形工具、Web 应用、自定义程序等。
- **并发**：每个连接对应一个独立后端进程；客户端与后端直接通信。

> 注意：客户端能访问的文件，服务器端不一定能访问（如 `COPY FROM` 文件路径必须在服务器上）。

---

## 3. 核心概念

### 3.1 层次结构

```
数据库集簇 (Cluster)
  └── 数据库 (Database)          ← 一个 PG 实例管理多个库
        └── 模式 (Schema)        ← 默认 public
              └── 表 (Table)
                    └── 行 (Row) × 列 (Column)
```

### 3.2 关键术语


| 术语                | 说明                             |
| ----------------- | ------------------------------ |
| **表（Table）**      | 命名的行集合，每行由相同列组成                |
| **列（Column）**     | 有固定数据类型；列顺序固定，但 SQL **不保证行顺序** |
| **关系（Relation）**  | 表的数学术语                         |
| **数据库（Database）** | 表的逻辑分组；通常每项目/每用户一个库            |
| **集簇（Cluster）**   | 单个 PG 实例管理的全部数据库               |


### 3.3 SQL 语法要点

- 关键字和标识符**不区分大小写**（除非用双引号 `"MyColumn"` 保留大小写）。
- `--` 开头为行注释。
- 语句以分号 `;` 结束。
- 空白（空格、换行、制表符）可自由使用。

---

## 4. 数据库与连接

### 4.1 创建与删除数据库

```bash
# 创建名为 mydb 的数据库
createdb mydb
createdb -U postql mydb

# 不指定名称时，默认创建与当前 OS 用户名同名的库
createdb

# 删除数据库（不可恢复！）
dropdb mydb
```

命名规则：以字母开头，长度小于 63 字符。

常见错误：


| 错误信息                                   | 原因         |
| -------------------------------------- | ---------- |
| `role "joe" does not exist`            | PG 用户账号未创建 |
| `permission denied to create database` | 当前用户无建库权限  |
| `connection ... failed`                | 服务器未启动或未监听 |


> PG 用户名与 OS 用户名是分开的；不指定 `-U` 时，默认使用当前 OS 用户名连接。

### 4.2 使用 psql 连接

```bash
psql mydb          # 连接 mydb
psql -U postgql mydb 
psql               # 默认连接与用户名同名的库
psql -s mydb       # 单步模式（每条语句执行前暂停，适合学习）
```

连接成功后的提示符：

```
mydb=>    # 普通用户
mydb=#    # 超级用户
```

### 4.3 psql 基础操作

```sql
-- 查询版本
SELECT version();

-- 当前日期
SELECT current_date;

-- 算术表达式
SELECT 2 + 2;

-- 退出
\q
```

**元命令**（以 `\` 开头，非 SQL）：


| 命令            | 作用         |
| ------------- | ---------- |
| `\h`          | SQL 命令帮助   |
| `\?`          | psql 元命令帮助 |
| `\i file.sql` | 执行 SQL 文件  |
| `\q`          | 退出         |


加载教程示例：

```bash
cd .../src/tutorial && make
psql -s mydb
\i basics.sql
```

---

## 5. DDL：创建与删除表

### 5.1 CREATE TABLE

```sql
CREATE TABLE weather (
    city            varchar(80),
    temp_lo         int,           -- 低温
    temp_hi         int,           -- 高温
    prcp            real,          -- 降水量
    date            date
);

CREATE TABLE cities (
    name            varchar(80),
    location        point          -- PG 特有：几何点类型
);
```

### 5.2 常用数据类型


| 类型                            | 说明          |
| ----------------------------- | ----------- |
| `int` / `smallint`            | 整数          |
| `real` / `double precision`   | 浮点          |
| `varchar(n)` / `text`         | 变长字符串       |
| `char(n)`                     | 定长字符串       |
| `date` / `time` / `timestamp` | 日期时间        |
| `interval`                    | 时间间隔        |
| `boolean`                     | 布尔          |
| `point`                       | 二维坐标（PG 扩展） |
| `numeric(p,s)`                | 精确数值        |


PG 支持自定义类型；类型名一般不是保留关键字。

### 5.3 DROP TABLE

```sql
DROP TABLE tablename;
```

---

## 6. DML：插入数据

### 6.1 INSERT 基本语法

```sql
-- 按列顺序插入全部列
INSERT INTO weather VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27');

-- 几何类型
INSERT INTO cities VALUES ('San Francisco', '(-194.0, 53.0)');

-- 显式指定列（推荐风格）
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
    VALUES ('San Francisco', 43, 57, 0.0, '1994-11-29');

-- 可改变列顺序或省略列（未知值存 NULL）
INSERT INTO weather (date, city, temp_hi, temp_lo)
    VALUES ('1994-11-29', 'Hayward', 54, 37);
```

规则：

- 非数字常量用**单引号** `'...'` 包裹。
- 省略的列值为 `NULL`。
- `date` 推荐格式：`'YYYY-MM-DD'`。

### 6.2 COPY 批量导入

比逐条 `INSERT` 更快，文件须在**服务器端**可访问：

```sql
COPY weather FROM '/home/user/weather.txt';
```

文件示例（制表符分隔，`\N` 表示 NULL）：

```
San Francisco    46    50    0.25    1994-11-27
San Francisco    43    57    0.0     1994-11-29
Hayward          37    54    \N      1994-11-29
```

---

## 7. DQL：查询数据

`SELECT` 由三部分组成：**选择列表**、**表列表**、**可选条件**。

### 7.1 基本查询

```sql
-- 所有列（学习可用，生产慎用）
SELECT * FROM weather;

-- 指定列
SELECT city, temp_lo, temp_hi, prcp, date FROM weather;
```

结果示例：

```
     city      | temp_lo | temp_hi | prcp |    date
---------------+---------+---------+------+------------
 San Francisco |      46 |      50 | 0.25 | 1994-11-27
 San Francisco |      43 |      57 |    0 | 1994-11-29
 Hayward       |      37 |      54 |      | 1994-11-29
```

### 7.2 表达式与别名

```sql
SELECT city, (temp_hi + temp_lo) / 2 AS temp_avg, date
FROM weather;
```

`AS` 为输出列命名（可省略，但建议写上）。

### 7.3 WHERE 过滤

```sql
-- 旧金山且有降水
SELECT * FROM weather
WHERE city = 'San Francisco' AND prcp > 0.0;
```

布尔运算符：`AND`、`OR`、`NOT`。

### 7.4 ORDER BY 排序

```sql
SELECT * FROM weather ORDER BY city;

-- 多列排序，结果稳定
SELECT * FROM weather ORDER BY city, temp_lo;
```

### 7.5 DISTINCT 去重

```sql
SELECT DISTINCT city FROM weather;

-- 与 ORDER BY 组合保证顺序一致
SELECT DISTINCT city FROM weather ORDER BY city;
```

> `DISTINCT` 不保证排序；需要有序结果时加 `ORDER BY`。

---

## 8. 表连接（JOIN）

一次查询访问多张表（或同表多次）称为 **连接查询**。

### 8.1 内连接（INNER JOIN）

```sql
-- 现代显式语法（推荐）
SELECT city, temp_lo, temp_hi, prcp, date, location
FROM weather JOIN cities ON city = name;

-- 限定表名（列名冲突时必需）
SELECT weather.city, weather.temp_lo, cities.location
FROM weather JOIN cities ON weather.city = cities.name;

-- 旧式隐式语法（等价，不推荐）
SELECT * FROM weather, cities WHERE city = name;
```

内连接只返回**两表都有匹配**的行（Hayward 在 `cities` 中无记录，故被排除）。

### 8.2 外连接（OUTER JOIN）

```sql
-- 左外连接：保留左表所有行，右表无匹配则填 NULL
SELECT *
FROM weather LEFT OUTER JOIN cities ON weather.city = cities.name;
```


| 类型                 | 行为        |
| ------------------ | --------- |
| `LEFT OUTER JOIN`  | 左表行至少出现一次 |
| `RIGHT OUTER JOIN` | 右表行至少出现一次 |
| `FULL OUTER JOIN`  | 两表行都保留    |


### 8.3 自连接（Self Join）

```sql
-- 找出温度范围"包含"另一行温度范围的记录
SELECT w1.city, w1.temp_lo AS low, w1.temp_hi AS high,
       w2.city, w2.temp_lo AS low, w2.temp_hi AS high
FROM weather w1
JOIN weather w2
    ON w1.temp_lo < w2.temp_lo AND w1.temp_hi > w2.temp_hi;
```

### 8.4 表别名

```sql
SELECT * FROM weather w JOIN cities c ON w.city = c.name;
```

---

## 9. 聚合函数与分组

聚合函数从多行计算出一个值：`count`、`sum`、`avg`、`max`、`min`。

### 9.1 基本聚合

```sql
SELECT max(temp_lo) FROM weather;
-- 结果: 46
```

### 9.2 聚合函数不能用在 WHERE 中

```sql
-- 错误：WHERE 在聚合之前执行
-- SELECT city FROM weather WHERE temp_lo = max(temp_lo);

-- 正确：用子查询
SELECT city FROM weather
WHERE temp_lo = (SELECT max(temp_lo) FROM weather);
```

### 9.3 GROUP BY 分组

```sql
SELECT city, count(*), max(temp_lo)
FROM weather
GROUP BY city;
```

```
     city      | count | max
---------------+-------+-----
 Hayward       |     1 |  37
 San Francisco |     2 |  46
```

### 9.4 HAVING 过滤分组

```sql
-- 只保留最低温最大值 < 40 的城市
SELECT city, count(*), max(temp_lo)
FROM weather
GROUP BY city
HAVING max(temp_lo) < 40;
```

### 9.5 WHERE vs HAVING


| 子句       | 执行时机            | 能否用聚合函数 |
| -------- | --------------- | ------- |
| `WHERE`  | 分组**之前**，筛选输入行  | 否       |
| `HAVING` | 分组**之后**，筛选分组结果 | 是       |


效率建议：能在 `WHERE` 写的条件不要放到 `HAVING`。

```sql
-- WHERE 先过滤，再分组（更高效）
SELECT city, count(*), max(temp_lo)
FROM weather
WHERE city LIKE 'S%'
GROUP BY city;
```

### 9.6 FILTER 子句

对**单个聚合**附加行过滤：

```sql
SELECT city,
       count(*) FILTER (WHERE temp_lo < 45),
       max(temp_lo)
FROM weather
GROUP BY city;
```

`count` 只统计 `temp_lo < 45` 的行；`max` 仍作用于该城市全部行。

---

## 10. 更新与删除

### 10.1 UPDATE

```sql
-- 11月28日之后的读数偏低 2 度，统一修正
UPDATE weather
SET temp_hi = temp_hi - 2,
    temp_lo = temp_lo - 2
WHERE date > '1994-11-28';

SELECT * FROM weather;
```

### 10.2 DELETE

```sql
DELETE FROM weather WHERE city = 'Hayward';
```

```sql
-- 危险：无 WHERE 将清空整表！
DELETE FROM tablename;
```

---

## 11. 视图（VIEW）

视图是**命名的查询**，使用时像普通表一样。

```sql
CREATE VIEW myview AS
    SELECT name, temp_lo, temp_hi, prcp, date, location
    FROM weather, cities
    WHERE city = name;

SELECT * FROM myview;
```

作用：

- 封装复杂查询，提供稳定接口。
- 隐藏表结构细节，便于应用演进。
- 可在视图之上再建视图。

---

## 12. 外键与引用完整性

外键（Foreign Key）保证子表引用的值在父表中存在。

### 12.1 定义主键与外键

```sql
CREATE TABLE cities (
    name     varchar(80) PRIMARY KEY,
    location point
);

CREATE TABLE weather (
    city     varchar(80) REFERENCES cities(name),
    temp_lo  int,
    temp_hi  int,
    prcp     real,
    date     date
);
```

### 12.2 违反外键约束

```sql
INSERT INTO weather VALUES ('Berkeley', 45, 53, 0.0, '1994-11-28');
```

```
ERROR:  insert or update on table "weather" violates foreign key constraint "weather_city_fkey"
DETAIL:  Key (city)=(Berkeley) is not present in table "cities".
```

外键行为（`ON DELETE`、`ON UPDATE` 等）可按业务定制，详见官方第 5 章。

---

## 13. 事务

事务将多个步骤捆绑为**原子操作**：要么全部成功，要么全部回滚。

### 13.1 ACID 要点


| 特性                   | 含义               |
| -------------------- | ---------------- |
| **原子性（Atomicity）**   | 全做或全不做           |
| **一致性（Consistency）** | 约束始终满足           |
| **隔离性（Isolation）**   | 未完成事务的修改对其他事务不可见 |
| **持久性（Durability）**  | 提交后写入磁盘，崩溃不丢     |


### 13.2 银行转账示例

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
UPDATE branches SET balance = balance - 100.00
    WHERE name = (SELECT branch_name FROM accounts WHERE name = 'Alice');
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
UPDATE branches SET balance = balance + 100.00
    WHERE name = (SELECT branch_name FROM accounts WHERE name = 'Bob');
COMMIT;
```

- `BEGIN` … `COMMIT`：提交事务块。
- `ROLLBACK`：放弃当前事务全部修改。
- 每条独立 SQL 语句隐含 `BEGIN` + `COMMIT`（自动提交）。

### 13.3 保存点（SAVEPOINT）

更细粒度地控制部分回滚：

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100.00 WHERE name = 'Alice';
SAVEPOINT my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Bob';
-- 发现应转给 Wally，回滚到保存点
ROLLBACK TO my_savepoint;
UPDATE accounts SET balance = balance + 100.00 WHERE name = 'Wally';
COMMIT;
```


| 命令                       | 作用             |
| ------------------------ | -------------- |
| `SAVEPOINT name`         | 在当前位置设保存点      |
| `ROLLBACK TO name`       | 回滚到保存点，保留之前的修改 |
| `RELEASE SAVEPOINT name` | 释放保存点          |


保存点操作在同一事务块内，对其他会话不可见。

---

## 14. 窗口函数

窗口函数在**与当前行关联的一组行**上计算，**不合并为多行**（与 `GROUP BY` 不同）。

### 14.1 准备示例表

```sql
CREATE TABLE empsalary (
    depname    text,
    empno      int,
    salary     int,
    enroll_date date
);
-- 插入教程数据后使用
```

### 14.2 PARTITION BY：按组计算

```sql
-- 每个员工与其部门平均工资对比
SELECT depname, empno, salary,
       avg(salary) OVER (PARTITION BY depname)
FROM empsalary;
```

`PARTITION BY depname` 将同部门行分为一组，在组内计算 `avg`。

### 14.3 ORDER BY：组内排序

```sql
SELECT depname, empno, salary,
       row_number() OVER (PARTITION BY depname ORDER BY salary DESC)
FROM empsalary;
```

`row_number()` 按薪水降序为每个部门内员工编号。

### 14.4 窗口帧（Frame）

```sql
-- 全表累计（无 PARTITION BY、无 ORDER BY）
SELECT salary, sum(salary) OVER () FROM empsalary;

-- 按薪水升序的 running total
SELECT salary, sum(salary) OVER (ORDER BY salary) FROM empsalary;
```

默认帧规则：

- 有 `ORDER BY`：从分区开始到当前行（含相等行）。
- 无 `ORDER BY`：整个分区。

### 14.5 使用限制

窗口函数只能出现在 `SELECT` 和 `ORDER BY` 中，**不能**用于 `WHERE`、`GROUP BY`、`HAVING`。

过滤窗口计算结果需用子查询：

```sql
SELECT depname, empno, salary, enroll_date
FROM (
    SELECT depname, empno, salary, enroll_date,
           row_number() OVER (
               PARTITION BY depname ORDER BY salary DESC, empno
           ) AS pos
    FROM empsalary
) AS ss
WHERE pos < 3;   -- 每个部门薪水前 2 名
```

### 14.6 WINDOW 子句复用定义

```sql
SELECT sum(salary) OVER w, avg(salary) OVER w
FROM empsalary
WINDOW w AS (PARTITION BY depname ORDER BY salary DESC);
```

---

## 15. 表继承

继承来自面向对象数据库，子表自动拥有父表列。

### 15.1 问题场景

首都也是城市，查询"所有城市"时应包含首都，但更新时需要区分。

### 15.2 INHERITS 语法

```sql
CREATE TABLE cities (
    name       text,
    population real,
    elevation  int     -- 海拔（英尺）
);

CREATE TABLE capitals (
    state      char(2) UNIQUE NOT NULL
) INHERITS (cities);
```

`capitals` 继承 `cities` 的 `name`、`population`、`elevation`，并新增 `state` 列。

### 15.3 查询继承层次

```sql
-- 查所有城市（含首都）
SELECT name, elevation FROM cities WHERE elevation > 500;

-- 只查 cities 本身，不含子表
SELECT name, elevation
FROM ONLY cities
WHERE elevation > 500;
```

`SELECT`、`UPDATE`、`DELETE` 均支持 `ONLY` 关键字。

### 15.4 限制

继承与唯一约束、外键的集成有限，生产环境更常用**表分区**或**单表 + 类型列**替代。

---

## 16. 速查与最佳实践

### 16.1 SQL 命令速查


| 操作   | 语法                                           |
| ---- | -------------------------------------------- |
| 建表   | `CREATE TABLE ...`                           |
| 删表   | `DROP TABLE ...`                             |
| 插入   | `INSERT INTO ... VALUES ...`                 |
| 批量导入 | `COPY table FROM 'file'`                     |
| 查询   | `SELECT ... FROM ... WHERE ... ORDER BY ...` |
| 连接   | `FROM a JOIN b ON ...`                       |
| 分组   | `GROUP BY ... HAVING ...`                    |
| 更新   | `UPDATE ... SET ... WHERE ...`               |
| 删除   | `DELETE FROM ... WHERE ...`                  |
| 视图   | `CREATE VIEW ... AS SELECT ...`              |
| 事务   | `BEGIN; ... COMMIT;` / `ROLLBACK;`           |


### 16.2 教程强调的最佳实践

1. **显式列出 INSERT 列名**，不依赖隐式列顺序。
2. **生产代码避免 `SELECT *`**，防止表结构变更破坏应用。
3. **JOIN 时限定表名**（`weather.city`），避免列名冲突。
4. **优先用显式 `JOIN ... ON`**，语义比逗号 + `WHERE` 更清晰。
5. **聚合条件放 `WHERE`（行级）或 `HAVING`（组级）**，不要混用。
6. **使用外键**维护引用完整性。
7. **多步写操作用事务**包裹，保证原子性。
8. `**DELETE` 必须带 `WHERE`**，除非确实要清空表。

### 16.3 完整示例：从零演练

```bash
createdb mydb
psql mydb
```

```sql
-- 1. 建表
CREATE TABLE cities (
    name     varchar(80) PRIMARY KEY,
    location point
);
CREATE TABLE weather (
    city    varchar(80) REFERENCES cities(name),
    temp_lo int, temp_hi int, prcp real, date date
);

-- 2. 插入
INSERT INTO cities VALUES ('San Francisco', '(-194.0, 53.0)');
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
    VALUES ('San Francisco', 46, 50, 0.25, '1994-11-27');

-- 3. 查询
SELECT w.city, w.temp_hi, c.location
FROM weather w JOIN cities c ON w.city = c.name;

-- 4. 更新
UPDATE weather SET temp_hi = temp_hi - 2 WHERE date > '1994-11-27';

-- 5. 视图
CREATE VIEW city_weather AS
    SELECT c.name, w.temp_lo, w.temp_hi, w.date, c.location
    FROM weather w JOIN cities c ON w.city = c.name;

-- 6. 清理
DROP VIEW city_weather;
DROP TABLE weather;
DROP TABLE cities;
```

---

## 17. SQL 命令参考（按重要性分级）

> 覆盖 `psql \h` 列出的全部 SQL 命令，按**日常使用频率**分为五级。  
> 详细语法见 [SQL 命令索引](http://www.postgres.cn/docs/current/sql-commands.html)。

### 重要性分级总览


| 级别            | 适用人群     | 典型场景                   |
| ------------- | -------- | ---------------------- |
| ⭐⭐⭐ **一级：必会** | 所有开发者    | CRUD、建表改表、索引、事务、COPY   |
| ⭐⭐ **二级：常用**  | 后端 / DBA | 库表管理、视图、序列、权限、EXPLAIN  |
| ⭐ **三级：进阶**   | 运维 / 架构师 | 物化视图、扩展、锁、监听通知、维护      |
| ○ **四级：专项**   | 特定场景     | FDW、逻辑复制、RLS、预编译、两阶段提交 |
| · **五级：专家**   | 扩展开发者    | 自定义算子/聚合、事件触发器、访问方法    |


---

### 一级：必会（日常开发）

#### SELECT — 查询数据

```sql
-- 基本查询
SELECT col1, col2 FROM table_name WHERE condition ORDER BY col1 LIMIT 10 OFFSET 0;

-- 去重、聚合、连接（见第 7–9 章）
SELECT DISTINCT city FROM weather;
SELECT city, count(*) FROM weather GROUP BY city HAVING count(*) > 1;
SELECT * FROM weather w JOIN cities c ON w.city = c.name;

-- 子查询、CTE
WITH hot AS (SELECT * FROM weather WHERE temp_hi > 50)
SELECT * FROM hot WHERE city LIKE 'S%';

-- 锁定行（FOR UPDATE 在事务内使用）
SELECT * FROM accounts WHERE id = 1 FOR UPDATE;
```

#### INSERT — 插入行

```sql
INSERT INTO weather (city, temp_lo, temp_hi, date)
VALUES ('Portland', 40, 55, '2024-01-01');

-- 多行
INSERT INTO weather (city, temp_lo, temp_hi, date) VALUES
    ('A', 1, 2, '2024-01-01'),
    ('B', 3, 4, '2024-01-02');

-- 从查询插入
INSERT INTO weather_backup SELECT * FROM weather WHERE date < '2020-01-01';

-- 冲突时忽略或更新（UPSERT）
INSERT INTO cities (name, location) VALUES ('SF', '(0,0)')
ON CONFLICT (name) DO UPDATE SET location = EXCLUDED.location;

-- 返回插入的行
INSERT INTO cities (name) VALUES ('New York') RETURNING name;
```

#### UPDATE — 更新行

```sql
UPDATE weather SET temp_hi = temp_hi - 2 WHERE date > '1994-11-28';
UPDATE weather SET prcp = 0 WHERE prcp IS NULL;

-- 用 FROM 联表更新
UPDATE weather w SET location = c.location
FROM cities c WHERE w.city = c.name;

-- 返回受影响的行
UPDATE weather SET temp_lo = 0 WHERE city = 'Hayward' RETURNING *;
```

#### DELETE — 删除行

```sql
DELETE FROM weather WHERE city = 'Hayward';

-- 用 USING 联表删除
DELETE FROM weather w USING cities c
WHERE w.city = c.name AND c.name = 'Hayward';

DELETE FROM weather WHERE date < '1990-01-01' RETURNING city, date;
-- 危险：DELETE FROM weather; 清空全表
```

#### CREATE TABLE — 建表

```sql
CREATE TABLE users (
    id          bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email       text NOT NULL UNIQUE,
    name        varchar(100),
    created_at  timestamptz NOT NULL DEFAULT now(),
    meta        jsonb DEFAULT '{}'
);

-- 临时表（会话结束自动删除）
CREATE TEMP TABLE tmp_import (id int, data text) ON COMMIT DROP;

-- 继承（见第 15 章）
CREATE TABLE capitals (state char(2)) INHERITS (cities);
```

#### ALTER TABLE — 修改表结构

```sql
-- 列操作
ALTER TABLE users ADD COLUMN phone text;
ALTER TABLE users DROP COLUMN phone;
ALTER TABLE users ALTER COLUMN name SET NOT NULL;
ALTER TABLE users ALTER COLUMN name TYPE varchar(200);
ALTER TABLE users RENAME COLUMN name TO full_name;
ALTER TABLE users RENAME TO app_users;

-- 约束
ALTER TABLE weather ADD CONSTRAINT fk_city
    FOREIGN KEY (city) REFERENCES cities(name);
ALTER TABLE users ADD CONSTRAINT uk_email UNIQUE (email);
ALTER TABLE users DROP CONSTRAINT uk_email;

-- 索引（也可单独 CREATE INDEX）
CREATE INDEX idx_users_email ON users (email);
ALTER TABLE users ADD PRIMARY KEY (id);
```

#### DROP TABLE — 删表

```sql
DROP TABLE weather;                          -- 报错若存在依赖
DROP TABLE IF EXISTS weather CASCADE;        -- 级联删除依赖对象
```

#### CREATE INDEX / DROP INDEX — 索引

```sql
-- B-tree（默认，等值与范围）
CREATE INDEX idx_weather_city ON weather (city);
CREATE INDEX idx_weather_date ON weather (date DESC);

-- 复合、部分、唯一索引
CREATE INDEX idx_city_date ON weather (city, date);
CREATE INDEX idx_sf ON weather (city) WHERE city = 'San Francisco';
CREATE UNIQUE INDEX idx_cities_name ON cities (name);

-- 表达式索引
CREATE INDEX idx_lower_email ON users (lower(email));

DROP INDEX idx_weather_city;
DROP INDEX CONCURRENTLY idx_weather_date;   -- 不阻塞写入（生产推荐）
```

#### ALTER INDEX — 索引维护

```sql
ALTER INDEX idx_weather_city RENAME TO idx_weather_city_name;
ALTER INDEX idx_weather_city SET TABLESPACE fastdisk;
ALTER INDEX ALL IN TABLE weather SET (fillfactor = 90);
```

#### COPY — 高速批量导入导出

```sql
-- 从文件导入（路径在**服务器**端）
COPY weather FROM '/tmp/weather.csv' WITH (FORMAT csv, HEADER true);

-- 导出
COPY weather TO '/tmp/export.csv' WITH (FORMAT csv, HEADER true);

-- 客户端 COPY（psql \copy，路径在**客户端**）
-- \copy weather FROM 'local.csv' CSV HEADER
```

#### 事务控制

```sql
BEGIN;                    -- 或 START TRANSACTION
-- ... SQL ...
COMMIT;                   -- 提交

BEGIN;
-- ...
ROLLBACK;                 -- 全部撤销

SAVEPOINT sp1;
-- ...
ROLLBACK TO SAVEPOINT sp1;  -- 部分撤销
RELEASE SAVEPOINT sp1;

-- ABORT 是 ROLLBACK 的别名
ABORT;
```


| 命令                            | 作用                     |
| ----------------------------- | ---------------------- |
| `BEGIN` / `START TRANSACTION` | 开启事务块                  |
| `COMMIT`                      | 提交                     |
| `ROLLBACK` / `ABORT`          | 回滚                     |
| `SAVEPOINT name`              | 设保存点                   |
| `ROLLBACK TO SAVEPOINT name`  | 回滚到保存点                 |
| `RELEASE SAVEPOINT name`      | 释放保存点                  |
| `END`                         | `COMMIT` 的别名           |
| `SET TRANSACTION`             | 设置隔离级别等（须在 BEGIN 后第一条） |


```sql
BEGIN;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET TRANSACTION READ ONLY;
-- ...
COMMIT;
```

#### SET / SHOW / RESET — 会话参数

```sql
SET work_mem = '256MB';              -- 当前会话
SET LOCAL statement_timeout = '5s';  -- 仅当前事务
SHOW work_mem;
SHOW ALL;                            -- 全部参数
RESET work_mem;                      -- 恢复默认值
RESET ALL;
```

---

### 二级：常用（Schema 与权限）

#### CREATE DATABASE / DROP DATABASE

```sql
CREATE DATABASE myapp ENCODING 'UTF8' LC_COLLATE 'en_US.UTF-8' TEMPLATE template0;
CREATE DATABASE myapp OWNER app_user;

DROP DATABASE myapp;                 -- 需断开所有连接
-- 命令行等效：createdb / dropdb
```

#### ALTER DATABASE

```sql
ALTER DATABASE myapp SET work_mem = '64MB';   -- 连接该库时的默认值
ALTER DATABASE myapp RENAME TO myapp_prod;
ALTER DATABASE myapp OWNER TO admin;
```

#### CREATE SCHEMA / ALTER SCHEMA / DROP SCHEMA

```sql
CREATE SCHEMA audit AUTHORIZATION admin;
CREATE SCHEMA IF NOT EXISTS staging;

ALTER SCHEMA audit RENAME TO archive;
ALTER SCHEMA audit OWNER TO admin;

DROP SCHEMA staging CASCADE;
```

#### CREATE VIEW / DROP VIEW

```sql
CREATE VIEW city_weather AS
    SELECT c.name, w.temp_hi, w.date
    FROM weather w JOIN cities c ON w.city = c.name;

CREATE OR REPLACE VIEW city_weather AS SELECT ...;

DROP VIEW city_weather;
DROP VIEW IF EXISTS city_weather CASCADE;
```

#### CREATE TABLE AS / SELECT INTO — 查询结果建表

```sql
-- CREATE TABLE AS（推荐，标准 SQL）
CREATE TABLE weather_2024 AS
    SELECT * FROM weather WHERE date >= '2024-01-01';

CREATE TABLE weather_summary AS
    SELECT city, avg(temp_hi) AS avg_hi FROM weather GROUP BY city;

-- SELECT INTO（PG 扩展，不能加约束）
SELECT * INTO weather_copy FROM weather WHERE 1=0;  -- 只复制结构
```

#### CREATE SEQUENCE / ALTER SEQUENCE / DROP SEQUENCE

```sql
CREATE SEQUENCE order_id_seq START 1000 INCREMENT 1;

-- 使用
INSERT INTO orders (id, ...) VALUES (nextval('order_id_seq'), ...);
SELECT currval('order_id_seq');
SELECT lastval();

ALTER SEQUENCE order_id_seq RESTART WITH 1;
ALTER SEQUENCE order_id_seq OWNED BY orders.id;   -- 列删则序列同删

DROP SEQUENCE order_id_seq;
```

> 现代推荐用 `GENERATED ... AS IDENTITY` 代替手动序列。

#### CREATE TYPE / DROP TYPE — 自定义类型

```sql
CREATE TYPE mood AS ENUM ('happy', 'sad', 'neutral');
CREATE TYPE address AS (street text, city text, zip text);

ALTER TYPE mood ADD VALUE 'excited' AFTER 'happy';
DROP TYPE mood;
```

#### CREATE DOMAIN / ALTER DOMAIN / DROP DOMAIN — 带约束的类型

```sql
CREATE DOMAIN us_postal_code AS text
    CHECK (VALUE ~ '^\d{5}(-\d{4})?$');

ALTER DOMAIN us_postal_code ADD CONSTRAINT not_empty CHECK (length(VALUE) > 0);
DROP DOMAIN us_postal_code;
```

#### COMMENT — 对象注释

```sql
COMMENT ON TABLE users IS '应用用户表';
COMMENT ON COLUMN users.email IS '登录邮箱，唯一';
COMMENT ON INDEX idx_users_email IS '邮箱查询索引';
```

#### GRANT / REVOKE — 权限

```sql
-- 授予
GRANT SELECT, INSERT ON users TO app_role;
GRANT ALL PRIVILEGES ON DATABASE myapp TO admin;
GRANT USAGE ON SCHEMA public TO app_role;
GRANT EXECUTE ON FUNCTION calc_tax(numeric) TO app_role;

-- 撤销
REVOKE INSERT ON users FROM app_role;
REVOKE ALL ON DATABASE myapp FROM old_admin;

-- 列级权限
GRANT SELECT (id, name) ON users TO reporter;
```

常用权限：`SELECT` `INSERT` `UPDATE` `DELETE` `TRUNCATE` `REFERENCES` `TRIGGER` `CREATE` `CONNECT` `TEMPORARY` `EXECUTE` `USAGE`。

#### CREATE ROLE / ALTER ROLE / DROP ROLE

> `CREATE USER` 与 `CREATE ROLE` 等价，仅 `LOGIN` 默认值不同。

```sql
CREATE ROLE app_user LOGIN PASSWORD 'secret' CONNECTION LIMIT 50;
CREATE ROLE readonly NOLOGIN;
CREATE USER admin WITH SUPERUSER PASSWORD 'xxx';   -- 等价 CREATE ROLE ... LOGIN SUPERUSER

ALTER ROLE app_user WITH PASSWORD 'new_secret';
ALTER ROLE app_user SET statement_timeout = '30s';

DROP ROLE app_user;
-- DROP USER app_user;  与 DROP ROLE 完全等价
```

#### CREATE GROUP / ALTER GROUP / DROP GROUP

> 已废弃别名，等价于 `ROLE` + `GRANT role TO member`。

```sql
CREATE GROUP dev_team;
GRANT dev_team TO alice, bob;
ALTER GROUP dev_team ADD USER charlie;
DROP GROUP dev_team;
```

#### ALTER DEFAULT PRIVILEGES — 默认权限

```sql
-- 以后 alice 在 public 下新建的表，自动给 app_role 只读
ALTER DEFAULT PRIVILEGES FOR ROLE alice IN SCHEMA public
    GRANT SELECT ON TABLES TO app_role;
```

#### SET ROLE / SET SESSION AUTHORIZATION — 切换身份

```sql
SET ROLE app_user;              -- 切换到 app_user 权限
RESET ROLE;                     -- 恢复
SET SESSION AUTHORIZATION admin; -- 超级用户可模拟任意角色
```

#### EXPLAIN — 执行计划

```sql
EXPLAIN SELECT * FROM weather WHERE city = 'SF';
EXPLAIN (ANALYZE, BUFFERS, FORMAT TEXT)
    SELECT * FROM weather WHERE date > '2020-01-01';
EXPLAIN (COSTS false) SELECT ...;
```

#### DO — 匿名代码块（PL/pgSQL）

```sql
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
        CREATE ROLE app_user LOGIN PASSWORD 'secret';
    END IF;
END $$;
```

---

### 三级：进阶（运维与对象管理）

#### CREATE FUNCTION / ALTER FUNCTION / DROP FUNCTION

```sql
CREATE OR REPLACE FUNCTION add(a int, b int) RETURNS int
    LANGUAGE sql IMMUTABLE AS $$ SELECT a + b $$;

CREATE OR REPLACE FUNCTION get_user(id bigint) RETURNS SETOF users
    LANGUAGE sql STABLE AS $$ SELECT * FROM users WHERE users.id = $1 $$;

ALTER FUNCTION add(int, int) RENAME TO add_int;
ALTER FUNCTION add(int, int) OWNER TO admin;
DROP FUNCTION add(int, int);
```

#### CREATE PROCEDURE / ALTER PROCEDURE / DROP PROCEDURE

> 存储过程支持事务控制（COMMIT/ROLLBACK 在过程体内）。

```sql
CREATE PROCEDURE transfer(from_id int, to_id int, amount numeric)
LANGUAGE plpgsql AS $$
BEGIN
    UPDATE accounts SET balance = balance - amount WHERE id = from_id;
    UPDATE accounts SET balance = balance + amount WHERE id = to_id;
END;
$$;

CALL transfer(1, 2, 100.00);
ALTER PROCEDURE transfer(int, int, numeric) OWNER TO admin;
DROP PROCEDURE transfer(int, int, numeric);
```

#### ALTER ROUTINE / DROP ROUTINE — 函数与过程通用

```sql
ALTER ROUTINE add(int, int) SET search_path = public;
DROP ROUTINE IF EXISTS add(int, int);
```

#### CREATE TRIGGER / DROP TRIGGER

```sql
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER trg_users_updated ON users;
```

#### CREATE MATERIALIZED VIEW / ALTER MATERIALIZED VIEW / REFRESH / DROP

```sql
CREATE MATERIALIZED VIEW mv_city_stats AS
    SELECT city, count(*), avg(temp_hi) FROM weather GROUP BY city;

CREATE UNIQUE INDEX ON mv_city_stats (city);   -- 支持 CONCURRENTLY 刷新

REFRESH MATERIALIZED VIEW mv_city_stats;
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_city_stats;

ALTER MATERIALIZED VIEW mv_city_stats RENAME TO mv_stats;
DROP MATERIALIZED VIEW mv_city_stats;
```

#### CREATE EXTENSION / ALTER EXTENSION / DROP EXTENSION

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;      -- 模糊搜索
CREATE EXTENSION postgis;                    -- 地理信息
CREATE EXTENSION vector;                     -- pgvector

ALTER EXTENSION postgis UPDATE TO '3.4.0';
DROP EXTENSION pg_trgm;
```

#### REINDEX — 重建索引

```sql
REINDEX INDEX idx_weather_city;
REINDEX TABLE weather;
REINDEX DATABASE myapp;
REINDEX INDEX CONCURRENTLY idx_weather_city;  -- 不阻塞写入
```

#### CLUSTER — 按索引物理重排表

```sql
CLUSTER weather USING idx_weather_date;   -- 一次性聚簇
ALTER TABLE weather CLUSTER ON idx_weather_date;  -- 设置 VACUUM 时自动 CLUSTER
CLUSTER;  -- 对所有设置了 cluster 的表执行
```

#### CHECKPOINT — 强制刷盘

```sql
CHECKPOINT;   -- 通常仅 DBA 故障排查或备份前使用
```

#### LOCK — 显式锁

```sql
BEGIN;
LOCK TABLE accounts IN ACCESS EXCLUSIVE MODE;
-- 迁移 DDL 前可锁表
COMMIT;
```

#### LISTEN / NOTIFY — 异步通知

```sql
-- 会话 A
LISTEN order_created;

-- 会话 B
NOTIFY order_created, '{"id": 123}';
```

#### ALTER TABLESPACE / CREATE TABLESPACE

```sql
CREATE TABLESPACE fastdisk LOCATION '/data/pg_fast';
ALTER TABLE users SET TABLESPACE fastdisk;
ALTER TABLESPACE fastdisk RENAME TO fastdisk2;
ALTER TABLESPACE fastdisk OWNER TO admin;
```

#### ALTER SYSTEM — 持久化配置

```sql
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM RESET work_mem;
-- 需 pg_ctl reload 或 SELECT pg_reload_conf();
```

#### DISCARD — 释放会话资源

```sql
DISCARD PLANS;      -- 清缓存的执行计划
DISCARD TEMP;       -- 删临时表
DISCARD SEQUENCES;  -- 重置 currval 状态
DISCARD ALL;        -- 以上全部
```

#### SECURITY LABEL — 安全标签（SELinux 等）

```sql
SECURITY LABEL ON TABLE users IS 'system_u:object_r:sepgsql_table_t:s0';
-- 需 sepgsql 等扩展，一般环境少见
```

---

### 四级：专项（FDW、复制、RLS、预编译）

#### PREPARE / EXECUTE / DEALLOCATE — 预编译语句

```sql
PREPARE get_weather (text) AS
    SELECT * FROM weather WHERE city = $1;

EXECUTE get_weather ('San Francisco');
DEALLOCATE get_weather;
DEALLOCATE ALL;
```

#### DECLARE / FETCH / MOVE / CLOSE — SQL 游标

```sql
BEGIN;
DECLARE cur CURSOR FOR SELECT * FROM weather ORDER BY date;
FETCH 10 FROM cur;
MOVE FORWARD 5 IN cur;
FETCH ALL FROM cur;
CLOSE cur;
COMMIT;
```

#### PREPARE TRANSACTION / COMMIT PREPARED / ROLLBACK PREPARED — 两阶段提交

```sql
BEGIN;
UPDATE accounts SET balance = balance - 100 WHERE id = 1;
PREPARE TRANSACTION 'txn_001';

COMMIT PREPARED 'txn_001';      -- 协调者提交
-- ROLLBACK PREPARED 'txn_001'; -- 协调者回滚
```

#### SET CONSTRAINTS — 约束检查时机

```sql
BEGIN;
SET CONSTRAINTS ALL DEFERRED;   -- 约束推迟到 COMMIT 时检查
INSERT INTO ...;
COMMIT;
```

#### CREATE PUBLICATION / ALTER PUBLICATION / DROP PUBLICATION — 逻辑复制发布端

```sql
CREATE PUBLICATION pub_orders FOR TABLE orders, order_items;
ALTER PUBLICATION pub_orders ADD TABLE customers;
ALTER PUBLICATION pub_orders SET (publish = 'insert,update');
DROP PUBLICATION pub_orders;
```

#### CREATE SUBSCRIPTION / ALTER SUBSCRIPTION / DROP SUBSCRIPTION — 订阅端

```sql
CREATE SUBSCRIPTION sub_orders
    CONNECTION 'host=pubhost dbname=myapp user=repl'
    PUBLICATION pub_orders;

ALTER SUBSCRIPTION sub_orders REFRESH PUBLICATION;
ALTER SUBSCRIPTION sub_orders SET (slot_name = 'sub_orders_slot');
DROP SUBSCRIPTION sub_orders;
```

#### CREATE FOREIGN DATA WRAPPER / ALTER / DROP — 外部数据包装器

```sql
CREATE EXTENSION postgres_fdw;
CREATE FOREIGN DATA WRAPPER postgres_fdw HANDLER postgres_fdw_handler
    VALIDATOR postgres_fdw_validator;

ALTER FOREIGN DATA WRAPPER postgres_fdw OPTIONS (ADD foo 'bar');
DROP FOREIGN DATA WRAPPER postgres_fdw CASCADE;
```

#### CREATE SERVER / ALTER SERVER / DROP SERVER — FDW 服务器

```sql
CREATE SERVER remote_pg FOREIGN DATA WRAPPER postgres_fdw
    OPTIONS (host '10.0.0.2', dbname 'remote_db', port '5432');

ALTER SERVER remote_pg OPTIONS (SET host '10.0.0.3');
DROP SERVER remote_pg CASCADE;
```

#### CREATE USER MAPPING / DROP USER MAPPING — FDW 用户映射

```sql
CREATE USER MAPPING FOR local_user SERVER remote_pg
    OPTIONS (user 'remote_user', password 'secret');

DROP USER MAPPING FOR local_user SERVER remote_pg;
```

#### CREATE FOREIGN TABLE / ALTER FOREIGN TABLE / DROP / IMPORT FOREIGN SCHEMA

```sql
CREATE FOREIGN TABLE remote_weather (
    city text, temp_lo int, temp_hi int, date date
) SERVER remote_pg OPTIONS (schema_name 'public', table_name 'weather');

-- 从远程自动导入表定义
IMPORT FOREIGN SCHEMA public LIMIT TO (weather, cities)
    FROM SERVER remote_pg INTO staging;

ALTER FOREIGN TABLE remote_weather OPTIONS (SET table_name 'weather_v2');
DROP FOREIGN TABLE remote_weather;
```

#### CREATE POLICY / ALTER POLICY / DROP POLICY — 行级安全 RLS

```sql
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

CREATE POLICY orders_own ON orders
    FOR ALL TO app_user
    USING (user_id = current_user_id())
    WITH CHECK (user_id = current_user_id());

ALTER POLICY orders_own ON orders USING (true);  -- 谨慎修改
DROP POLICY orders_own ON orders;
```

#### CREATE RULE / ALTER RULE / DROP RULE — 查询重写规则

```sql
CREATE RULE weather_insert AS ON INSERT TO weather_view
    DO INSTEAD INSERT INTO weather VALUES (NEW.*);

ALTER RULE weather_insert ON weather_view RENAME TO weather_ins;
DROP RULE weather_insert ON weather_view;
-- 多数场景用 VIEW + TRIGGER 替代 RULE
```

#### REASSIGN OWNED / DROP OWNED — 对象归属

```sql
REASSIGN OWNED BY old_user TO new_user;
DROP OWNED BY old_user;   -- 删除该用户拥有的所有对象
```

#### LOAD — 加载共享库

```sql
LOAD 'auto_explain';   -- 加载 auto_explain 模块
```

---

### 五级：专家级（扩展开发 / 内部机制）

以下命令日常开发极少直接使用，多用于编写扩展、定制排序/索引方法或深度运维。

#### CREATE AGGREGATE / ALTER AGGREGATE / DROP AGGREGATE

```sql
-- 自定义聚合：几何平均
CREATE AGGREGATE geom_avg(numeric) (
    SFUNC = numeric_mul,
    STYPE = numeric,
    FINALFUNC = numeric_sqrt,
    INITCOND = '1'
);
ALTER AGGREGATE geom_avg(numeric) OWNER TO admin;
DROP AGGREGATE geom_avg(numeric);
```

#### CREATE CAST / DROP CAST — 类型转换

```sql
CREATE CAST (text AS int) WITH INOUT AS ASSIGNMENT;
DROP CAST (text AS int);
```

#### CREATE COLLATION / ALTER COLLATION / DROP COLLATION

```sql
CREATE COLLATION german (LOCALE = 'de_DE.UTF-8');
ALTER COLLATION german RENAME TO german_ci;
DROP COLLATION german;
```

#### CREATE CONVERSION / ALTER CONVERSION / DROP CONVERSION

```sql
-- 编码转换函数，扩展开发用
CREATE CONVERSION my_conv FOR 'LATIN1' TO 'UTF8' FROM my_conv_func;
ALTER CONVERSION my_conv RENAME TO my_conv_v2;
DROP CONVERSION my_conv;
```

#### CREATE LANGUAGE / ALTER LANGUAGE / DROP LANGUAGE

```sql
CREATE LANGUAGE plpython3u HANDLER plpython3_call_handler
    INLINE plpython3_inline_handler VALIDATOR plpython3_validator;
ALTER LANGUAGE plpython3u RENAME TO plpython3;
DROP LANGUAGE plpython3u;
-- 常用 plpgsql 已内置
```

#### CREATE OPERATOR / ALTER OPERATOR / DROP OPERATOR

```sql
CREATE OPERATOR === (
    LEFTARG = text, RIGHTARG = text,
    PROCEDURE = texteq, COMMUTATOR = ===
);
ALTER OPERATOR ===(text, text) SET (RESTRICT = '-');
DROP OPERATOR ===(text, text);
```

#### CREATE OPERATOR CLASS / ALTER / DROP — 索引操作符类

```sql
CREATE OPERATOR CLASS int4_ops DEFAULT FOR TYPE int4 USING btree AS ...;
ALTER OPERATOR CLASS int4_ops USING btree RENAME TO int4_ops_v2;
DROP OPERATOR CLASS int4_ops USING btree;
```

#### CREATE OPERATOR FAMILY / ALTER / DROP — 操作符族

```sql
CREATE OPERATOR FAMILY custom_ops USING btree;
ALTER OPERATOR FAMILY custom_ops USING btree ADD OPERATOR 1 <(int, int);
DROP OPERATOR FAMILY custom_ops USING btree;
```

#### CREATE ACCESS METHOD / DROP ACCESS METHOD — 索引访问方法

```sql
CREATE ACCESS METHOD gist TYPE INDEX HANDLER gisthandler;
DROP ACCESS METHOD gist;
```

#### CREATE EVENT TRIGGER / ALTER EVENT TRIGGER / DROP EVENT TRIGGER

```sql
CREATE EVENT TRIGGER evtr_ddl ON ddl_command_end
    EXECUTE FUNCTION log_ddl();

ALTER EVENT TRIGGER evtr_ddl ENABLE;
DROP EVENT TRIGGER evtr_ddl;
```

#### CREATE STATISTICS / ALTER STATISTICS / DROP STATISTICS — 扩展统计

```sql
CREATE STATISTICS stts_city_date (dependencies)
    ON city, date FROM weather;
DROP STATISTICS stts_city_date;
```

#### ALTER STATISTICS

```sql
ALTER STATISTICS stts_city_date RENAME TO stts_weather;
```

#### ALTER LARGE OBJECT — 大对象

```sql
ALTER LARGE OBJECT 12345 OWNER TO admin;
-- 大对象读写通常用 lo_* 函数，非日常 SQL
```

#### 全文搜索对象

```sql
-- 解析器
CREATE TEXT SEARCH PARSER my_parser (...);
ALTER TEXT SEARCH PARSER my_parser RENAME TO my_parser_v2;
DROP TEXT SEARCH PARSER my_parser;

-- 词典
CREATE TEXT SEARCH DICTIONARY my_dict (TEMPLATE = simple);
ALTER TEXT SEARCH DICTIONARY my_dict (...);
DROP TEXT SEARCH DICTIONARY my_dict;

-- 模板
CREATE TEXT SEARCH TEMPLATE my_template (...);
DROP TEXT SEARCH TEMPLATE my_template;

-- 配置（最常用）
CREATE TEXT SEARCH CONFIGURATION english (COPY = pg_catalog.english);
ALTER TEXT SEARCH CONFIGURATION english
    ALTER MAPPING FOR asciiword WITH english_stem;
DROP TEXT SEARCH CONFIGURATION english;

-- 使用
SELECT to_tsvector('english', 'The quick brown fox');
SELECT to_tsquery('english', 'quick & fox');
CREATE INDEX idx_doc ON docs USING gin (to_tsvector('english', body));
```

#### ALTER TYPE — 枚举等类型变更

```sql
ALTER TYPE mood ADD VALUE 'angry';
ALTER TYPE mood RENAME TO emotion;
```

---

### 命令速查矩阵（按场景）


| 场景   | 推荐命令                                                   |
| ---- | ------------------------------------------------------ |
| 查数据  | `SELECT`                                               |
| 增删改  | `INSERT` `UPDATE` `DELETE`                             |
| 建表改表 | `CREATE TABLE` `ALTER TABLE` `DROP TABLE`              |
| 加速查询 | `CREATE INDEX` `EXPLAIN`                               |
| 批量数据 | `COPY`                                                 |
| 事务   | `BEGIN` `COMMIT` `ROLLBACK` `SAVEPOINT`                |
| 权限   | `GRANT` `REVOKE` `CREATE ROLE`                         |
| 库/模式 | `CREATE DATABASE` `CREATE SCHEMA`                      |
| 汇总缓存 | `CREATE MATERIALIZED VIEW` `REFRESH MATERIALIZED VIEW` |
| 逻辑复制 | `CREATE PUBLICATION` `CREATE SUBSCRIPTION`             |
| 跨库查询 | `CREATE FOREIGN TABLE` + `postgres_fdw`                |
| 行级权限 | `CREATE POLICY` + `ENABLE ROW LEVEL SECURITY`          |
| 计划分析 | `EXPLAIN (ANALYZE, BUFFERS)`                           |
| 索引维护 | `REINDEX` `CLUSTER`                                    |
| 参数调优 | `SET` `ALTER SYSTEM` `SHOW`                            |
| 预编译  | `PREPARE` `EXECUTE`                                    |
| 异步消息 | `LISTEN` `NOTIFY`                                      |


### 别名与等价关系


| 命令 A            | 等价于 B                      |
| --------------- | -------------------------- |
| `CREATE USER`   | `CREATE ROLE ... LOGIN`    |
| `DROP USER`     | `DROP ROLE`                |
| `CREATE GROUP`  | `CREATE ROLE ... NOLOGIN`  |
| `ABORT`         | `ROLLBACK`                 |
| `END`           | `COMMIT`                   |
| `ALTER ROUTINE` | 同时适用于 FUNCTION / PROCEDURE |
| `DROP ROUTINE`  | 同时适用于 FUNCTION / PROCEDURE |


---

## 参考链接

- [部分 I. 教程](http://www.postgres.cn/docs/current/tutorial.html)
- [SQL 命令索引](http://www.postgres.cn/docs/current/sql-commands.html)
- [第 1 章 入门](http://www.postgres.cn/docs/current/tutorial-start.html)
- [第 2 章 SQL 语言](http://www.postgres.cn/docs/current/tutorial-sql.html)
- [第 3 章 高级特性](http://www.postgres.cn/docs/current/tutorial-advanced.html)
- [PostgreSQL 官方网站](https://www.postgresql.org/)

