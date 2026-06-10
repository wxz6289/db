# MySQL 数据库级操作笔记

聚焦 **实例内的数据库（schema）**：创建与默认字符集、切换与查看、修改库级默认值、删除，以及 **存储引擎** 的选用。备份、用户与权限的完整示例见仓库根目录 [sql.md](../sql.md)（「数据库操作总结」一节）。

## 层次关系（库在哪里）

```mermaid
flowchart LR
  Client[Client]
  Server[MySQLServer]
  Schema[Schema_Database]
  Tables[Tables_Indexes]
  Client --> Server --> Schema --> Tables
```

---

## 1. 概念与术语

- 在 MySQL 中 **database 与 schema 同义**：创建的是同一个对象，只是语句关键字不同（`CREATE DATABASE` / `CREATE SCHEMA`）。
- `SHOW DATABASES` 与 `SHOW SCHEMAS` 等价。
- `SELECT DATABASE()` 与 `SELECT SCHEMA()` 等价，表示当前会话的「默认数据库」。

```sql
SHOW DATABASES;
SHOW SCHEMAS;
SELECT DATABASE(), SCHEMA();
```

---

## 2. 数据库命名规则与注意事项

### 2.1 合法标识符（常规写法）

- 数据库名属于 **MySQL 标识符**：未加反引号时，建议使用 **ASCII 字母、数字、下划线**，且 **不以数字开头** 更易读、也少踩坑。
- **最大长度 64 字符**（与表名等标识符上限一致）。
- 需要保留字、空格、连字符 `-` 或其它特殊字符时，必须用 **反引号** 括起来，例如 `` `my-db` ``；**生产环境不推荐** 依赖反引号与非常规字符，迁移与脚本里容易出错。
- **不要** 使用与系统库同名或易混淆的名字，例如：`mysql`、`information_schema`、`performance_schema`、`sys`。

### 2.2 与文件系统、大小写的关系

- 在 MySQL 中，库对应数据目录下的 **子目录名**（与部署平台有关）。
- **Linux** 上目录名通常 **区分大小写**；**Windows** 上文件系统往往 **不区分大小写**。跨环境迁移时，若库名大小写不一致，可能出现「同名不同大小写」冲突。
- **建议**：库名统一 **全小写** + **下划线分隔**（如 `order_service`），避免大小写混用，降低跨 OS / 备份还原时的风险。
- 实例参数 **`lower_case_table_names`** 会影响表名存储与比较方式；库名仍建议在团队内约定 **单一大小写规范**，不要依赖「碰巧能区分」的大小写。

### 2.3 命名风格与工程习惯（推荐）

| 建议 | 说明 |
| --- | --- |
| 语义清晰 | 与业务域或应用对应，如 `shop`、`billing`，避免无意义缩写 |
| 环境可区分 | 如 `shop_dev` / `shop_staging` / `shop_prod`，或通过不同实例隔离而非仅靠名字 |
| 避免保留字 | 不用 `order`、`group` 等 SQL 关键字作库名；若必须用，全程反引号且团队统一 |
| 字符集一致 | 库名本身多为 ASCII；库内数据用 `utf8mb4`，见下一节 |

### 2.4 权限与脚本注意

- 在 `GRANT` 的 `ON 库名.*` 目标中，若库名含保留字或特殊字符，须用 **反引号** 包裹库名；应用连接串、ORM 配置里同样注意转义，否则解析或连接失败。
- 自动化脚本里优先 **`IF NOT EXISTS` / `IF EXISTS`**，库名用 **固定白名单** 或变量校验，避免拼接用户输入导致误删、误连。

---

## 3. 创建数据库

语法要点：

```text
CREATE {DATABASE | SCHEMA} [IF NOT EXISTS] db_name
  [[DEFAULT] CHARACTER SET charset_name]
  [[DEFAULT] COLLATE collation_name];
```

实践上建议新建库即指定 **utf8mb4**，避免使用已废弃的 **`utf8`**（utf8mb3，最多三字节 Unicode，易截断 emoji 等四字节字符）。

```sql
CREATE DATABASE IF NOT EXISTS shop
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

-- MySQL 8 常见默认族（与安装/配置有关，以实例为准）
-- DEFAULT COLLATE utf8mb4_0900_ai_ci;

SHOW CREATE DATABASE shop;
```

---

## 4. 使用与查看

| 目的 | 语句 |
| --- | --- |
| 切换当前库 | `USE db_name;` |
| 当前库名 | `SELECT DATABASE();` |
| 列出所有库 | `SHOW DATABASES;` |

库级元数据也可查系统表：

```sql
USE shop;
SHOW TABLES;

SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME
FROM information_schema.SCHEMATA
WHERE SCHEMA_NAME = 'shop';
```

---

## 5. 修改数据库级默认字符集与排序规则

`ALTER DATABASE` 修改的是 **该库后续新建对象** 的默认字符集/排序规则；**已有表/列** 不会自动全部改写，需对具体对象执行 `ALTER TABLE` 等。

```sql
ALTER DATABASE shop
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

---

## 6. 删除数据库

- 删除库会移除其下所有表与数据，**不可恢复**（除非有备份）。
- 脚本中常用 `IF EXISTS`，避免库不存在时报错中断。

```sql
DROP DATABASE IF EXISTS shop;
```

生产环境：先备份、再限制能执行 `DROP` 的账号；操作前用 `SHOW CREATE DATABASE` / 导出确认对象。

---

## 7. 存储引擎选用

引擎是 **表级** 属性；同一库内可以混用多种引擎。事务若跨表，混用 **不支持事务** 的引擎会破坏「要么全提交、要么全回滚」的语义，需谨慎。

### 7.1 查看支持与默认

```sql
SHOW ENGINES;
SELECT @@default_storage_engine;
```

### 7.2 如何指定

```sql
CREATE TABLE t1 (
  id INT PRIMARY KEY
) ENGINE=InnoDB;
```

### 7.3 常见引擎怎么选（结论级）

| 引擎 | 事务 | 行级锁 | 典型用途 |
| --- | --- | --- | --- |
| **InnoDB** | 有 | 有 | **默认与首选**：OLTP、外键、崩溃恢复、并发写多读多 |
| **MyISAM** | 无 | 表级锁 | 历史只读/简单场景；新项目一般不作为主引擎 |
| **MEMORY** | 无 | 表级锁 | 临时数据、极短生命周期；**重启数据丢失** |
| CSV / ARCHIVE 等 | 视类型而定 | — | 导入导出、归档等窄场景 |

自 MySQL 5.5 起 **InnoDB** 为默认存储引擎：需要 **ACID 事务**、**行锁**、**外键** 时选 InnoDB。锁、隔离级别与死锁见仓库 [transaction.md](../transaction.md)；索引与 B+Tree 见 [index.md](../index.md)。

---

## 8. 其他库级相关内容（精简）

**数据目录**（数据文件所在路径）：

```sql
SELECT @@datadir;
```

**从 SQL 脚本初始化库**（示例：先建库再导入，或脚本内已含 `USE`）：

```bash
mysql -uroot -p < /path/to/schema.sql
mysql -uroot -p < /path/to/data.sql
```

**备份与恢复**（`mysqldump`、导入重定向）、**用户与库级权限**（`GRANT ... ON db_name.*`、最小权限原则）：见 [sql.md](../sql.md) 中「数据库备份与恢复」「数据库权限管理」小节。
