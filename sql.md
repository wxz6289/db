# SQL 语言概述

## SQL 通用语法
SQL 语句通常由关键字、列名、表名、条件表达式、函数、子句等组成。常见通用语法结构如下：

- `SELECT` 语句：
  - `SELECT <列列表>`：指定要查询的字段
  - `FROM <表名>`：指定查询来源表或视图
  - `WHERE <条件>`：过滤行
  - `GROUP BY <列>`：分组聚合
  - `HAVING <条件>`：对分组结果过滤
  - `ORDER BY <列> [ASC|DESC]`：排序
  - `LIMIT <数量>` / `FETCH FIRST <数量> ROWS ONLY`：限制结果行数

- `INSERT` 语句：
  - `INSERT INTO <表名> [(列1, 列2, ...)] VALUES (值1, 值2, ... )`
  - `INSERT INTO <表名> SELECT ...`：从查询结果插入

- `UPDATE` 语句：
  - `UPDATE <表名> SET 列1=值1, 列2=值2 WHERE <条件>`

- `DELETE` 语句：
  - `DELETE FROM <表名> WHERE <条件>`

- `CREATE TABLE` 基本语法：
  - `CREATE TABLE <表名> (
      列名1 数据类型 [约束],
      列名2 数据类型 [约束],
      ...
    )`

- 常见 SQL 关键字：
  - `AND` / `OR` / `NOT`
  - `IN` / `BETWEEN` / `LIKE` / `IS NULL`
  - `JOIN` / `INNER JOIN` / `LEFT JOIN` / `RIGHT JOIN` / `FULL JOIN`
  - `UNION` / `UNION ALL`
  - `EXISTS` / `CASE WHEN`

- 通用语法提示：
  - 关键字不区分大小写，但建议统一使用大写。
  - 列名和表名可加反引号、双引号或方括号，视数据库而定。
  - `WHERE` 条件通常放在 `FROM` 之后，`GROUP BY` 之后是 `HAVING`，最后是 `ORDER BY` 和 `LIMIT`。
  - 使用别名 `AS` 可以提高查询可读性。

## SQL 语句分类

SQL（Structured Query Language）用于关系型数据库的查询与操作。一般可按功能分为以下几类：
## 1. DDL（Data Definition Language）数据定义语言
用于定义数据库结构和对象，包括创建、修改、删除表、视图、索引、约束等。

常见语句：
- `CREATE`：创建数据库、表、视图、索引、存储过程等
- `ALTER`：修改数据库对象结构，例如添加或删除字段、修改字段类型
- `DROP`：删除数据库对象，例如表、视图、索引
- `TRUNCATE`：清空表数据（快速删除所有行），但不删除表结构
- `RENAME`：重命名表或其他数据库对象

## 2. DML（Data Manipulation Language）数据操作语言
用于对数据库中的数据进行增删改查。

常见语句：
- `SELECT`：查询数据
- `INSERT`：插入新记录
- `UPDATE`：更新已有记录
- `DELETE`：删除记录
- `MERGE`：合并数据（根据匹配条件插入或更新）

## 3. DCL（Data Control Language）数据控制语言
用于权限管理、访问控制、事务控制等安全相关操作。

常见语句：
- `GRANT`：授予权限
- `REVOKE`：撤销权限
- `DENY`：拒绝权限（某些数据库系统支持）

## 4. TCL（Transaction Control Language）事务控制语言
用于管理事务边界，保证数据一致性。

常见语句：
- `BEGIN TRANSACTION` / `START TRANSACTION`：开始事务
- `COMMIT`：提交事务，将修改保存到数据库
- `ROLLBACK`：回滚事务，撤销自事务开始以来的修改
- `SAVEPOINT`：设置保存点，支持部分回滚
- `SET TRANSACTION`：设置事务隔离级别

## 5. DQL（Data Query Language）数据查询语言
从广义上看，`SELECT` 语句通常单独归为 DQL。

- `SELECT`：查询数据，支持 `WHERE`、`JOIN`、`GROUP BY`、`HAVING`、`ORDER BY` 等子句

##  其他常见分类
- TCL 与 DCL 有时合并为 `TCL` 或 `DCL`，不同厂商命名可能不完全一致。
- `DDL`、`DML`、`DCL`、`TCL` 是最常见的四类划分。
- 在实际应用中，也有按目的分类的方式：查询类、事务类、控制类、定义类、扩展类等。

## 各类语句的典型用途
- `DDL`：建表、创建索引、修改结构、删除表
- `DML`：增删改查，数据录入与更新
- `DCL`：用户权限、角色管理、安全控制
- `TCL`：事务提交与回滚，确保多步操作的一致性
- `DQL`：报表查询、数据抽取、分析查询

##  实战提示
- 新表结构变更使用 `DDL`，生产环境需谨慎执行
- 对于批量数据修改使用 `DML`，注意备份和事务
- 生产环境权限管理尽量使用 `DCL`，避免授予过多权限
- 事务控制使用 `TCL` 保证操作原子性和一致性
- 查询优化仍然主要依赖 `SELECT`（`DQL`）与索引设计


## 数据库操作总结
数据库操作通常涉及数据库实例级别的管理，而非单个表或记录。常见操作包括：

### 数据库创建与删除
- 创建数据库：`CREATE DATABASE [if not exists] 数据库名 [CHARACTER SET 字符集] [COLLATE 排序规则]`
- 删除数据库：`DROP DATABASE [if exists] 数据库名`（谨慎使用，会删除所有数据）
- 切换数据库：`USE 数据库名`
- 查看数据库列表：`SHOW DATABASES`
- 查看当前数据库：`SELECT DATABASE()`

```sql
show databases;
create database  if not exists users;
drop database if exists users;
use shop;
select database();
-- database -> schema
show schemas;
show databases;
create database  if not exists users;

create database  if not exists products default character set utf8mb4 collate utf8mb4_unicode_ci;

use products;

show schemas;

select schema();
```

### 数据库备份与恢复
- 备份：使用工具如 `mysqldump`（MySQL）或 `pg_dump`（PostgreSQL）导出数据
- 恢复：使用 `mysql` 或 `psql` 导入备份文件
- 示例：`mysqldump -u 用户名 -p 数据库名 > 备份文件.sql`

### 数据库权限管理
- 创建用户：`CREATE USER '用户名'@'主机' IDENTIFIED BY '密码'`
- 授予权限：`GRANT 权限 ON 数据库.表 TO '用户名'@'主机'`
- 撤销权限：`REVOKE 权限 ON 数据库.表 FROM '用户名'@'主机'`
- 删除用户：`DROP USER '用户名'@'主机'`

### 数据库监控与维护
- 查看状态：`SHOW PROCESSLIST`（MySQL）或 `SELECT * FROM pg_stat_activity`（PostgreSQL）
- 优化表：`OPTIMIZE TABLE 表名`（MySQL）或 `VACUUM`（PostgreSQL）
- 查看数据库大小：`SELECT SUM(data_length + index_length) FROM information_schema.tables WHERE table_schema = '数据库名'`

### 实战要点
- 生产环境数据库操作前务必备份
- 权限管理遵循最小权限原则
- 定期监控数据库性能和磁盘使用情况
- 跨数据库迁移时注意字符集和数据类型兼容性

```sql
SELECT user, host FROM mysql.user WHERE user='king';
SHOW GRANTS FOR 'king'@'%';

CREATE USER 'king'@'%' IDENTIFIED BY 'king123';
GRANT ALL PRIVILEGES ON spring.* TO 'king'@'%';

-- 授予必要权限（如果需要）
GRANT RELOAD ON *.* TO 'king'@'%';

-- 刷新权限
FLUSH PRIVILEGES;
FLUSH PRIVILEGES;
```

可视化工具
- DataGrip
- Navicat
- MySQL Workbench
- DBeaver
- HeidiSQL

数据库设计
数据操作
数据库优化
