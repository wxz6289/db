# MySQL 表与列操作笔记

聚焦 **表与列的 DDL**：创建与删除表、重命名、修改表级/列级结构、字符集与排序规则，以及 **列名约定**、列类型、约束、主键/外键、索引和列的增删改。库级默认字符集见 [database.md](database.md)；库名约定见 [database.md 第 2 节](database.md#2-数据库命名规则与注意事项)；索引原理与优化见仓库 [index.md](../index.md)。

---

## 一、表级操作

### 1.1 创建表 `CREATE TABLE`

- 先 `USE 数据库名` 或写 **`库名.表名`**。
- 建议显式指定 **`ENGINE=InnoDB`**、**`DEFAULT CHARSET=utf8mb4`** 与 **`COLLATE`**（与库默认一致或按需指定）。

```sql
CREATE TABLE IF NOT EXISTS orders (
  id            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  user_id       BIGINT UNSIGNED NOT NULL,
  status        VARCHAR(16)     NOT NULL DEFAULT 'pending',
  created_at    DATETIME(3)     NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (id),
  KEY idx_orders_user (user_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci;
```

常用查看：

```sql
SHOW CREATE TABLE orders\G
SHOW TABLE STATUS LIKE 'orders'\G
```

从已有表复制结构（不含数据）：

```sql
CREATE TABLE orders_backup LIKE orders;
```

### 1.2 字符集与排序规则（表 / 列）

| 层级 | 作用 |
| --- | --- |
| 服务器 / 库 | 默认值来源，见 [database.md](database.md) |
| **表** | `CREATE TABLE ... DEFAULT CHARSET ... COLLATE ...` 作为该表未单独指定列的默认 |
| **列** | `VARCHAR(...) CHARACTER SET utf8mb4 COLLATE utf8mb4_bin` 可覆盖表默认 |

```sql
ALTER TABLE orders
  CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 或仅改默认（不转换已有数据语义时需配合数据迁移策略，生产慎用）
ALTER TABLE orders DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 1.3 修改表结构 `ALTER TABLE`

`ALTER TABLE` 可组合多项子句，大表在线变更需考虑锁时间与工具（如 Online DDL、外部变更工具）。

常见子句分类：

- **列**：`ADD` / `DROP` / `MODIFY` / `CHANGE` / `RENAME COLUMN`（见下文「列变更」）
- **索引**：`ADD INDEX` / `DROP INDEX` / `ADD PRIMARY KEY` 等
- **约束**：`ADD CONSTRAINT` / `DROP FOREIGN KEY`（需符号名）
- **表选项**：`ENGINE=`、`DEFAULT CHARSET`、`COLLATE`、`COMMENT`

### 1.4 重命名表

两种方式等价选用其一：

```sql
RENAME TABLE old_name TO new_name;

ALTER TABLE old_name RENAME TO new_name;
```

跨库移动：

```sql
RENAME TABLE db1.t TO db2.t;
```

### 1.5 删除表 `DROP TABLE`

```sql
DROP TABLE IF EXISTS orders;
```

删除后不可恢复（无备份则数据丢失）。生产环境限制 `DROP` 权限。

---

## 二、列：类型、默认值与表达式

### 2.1 列名命名规则与注意事项

#### 合法标识符

- 列名属于 **MySQL 标识符**，规则与表名一致：**最长 64 字符**；未加反引号时建议使用 **ASCII 字母、数字、下划线**，且 **不以数字开头**，减少工具链与驱动兼容问题。
- **保留字**、空格、连字符 `-` 等必须用 **反引号** 包裹（如 `` `order` ``、`` `select` ``）。生产环境 **不推荐** 依赖反引号与非常规字符，以免 ORM、报表与脚本批量生成 SQL 时出错。

#### 风格与可读性（推荐）

| 建议 | 说明 |
| --- | --- |
| 小写 + 下划线 | 如 `user_id`、`created_at`，与同库 [库名/表名风格](database.md#2-数据库命名规则与注意事项) 一致 |
| 主键 | 单表代理键常用 `id`；业务主键可用有语义的组合列，避免无缩写 |
| 外键列 | 指向 `users.id` 时常命名为 `user_id`，见名知意 |
| 布尔语义 | `is_active`、`is_deleted` 等优于含糊的 `flag` |
| 时间 | 时间点用 `_at`（`created_at`），纯日期用 `_date`；若存 UTC 可在团队文档约定列名后缀（如 `_utc`） |

#### 注意点

- **避免与关键字、常用函数同名**（如 `order`、`group`、`count`、`key`），否则查询中易与语法混淆，或被迫处处加反引号。
- **改名影响面大**：列名出现在应用、视图、存储过程、定时任务、导出脚本中；重命名前列出引用并做回归；大表配合 `ALTER TABLE ... RENAME COLUMN` / `CHANGE` 时注意锁与执行时间（见第五节）。
- **大小写**：列名在元数据里按创建时写法存储，MySQL 对列标识符的匹配通常 **不区分大小写**，但仍建议 **统一小写**，避免不同客户端、ORM 与手写 SQL 混用大小写造成可读性与代码审查成本。
- **语义稳定**：同一业务含义不要用多组列名（如 `mobile` / `phone` / `tel` 混用）；枚举类语义优先用 **显式列名 + 约束/字典表**，而非仅靠 `type`、`status` 承载过多互斥含义。

### 2.2 常用列类型（速查）

| 类别 | 类型示例 | 说明 |
| --- | --- | --- |
| 整数 | `TINYINT`, `INT`, `BIGINT` | 可用 `UNSIGNED`；`BOOL` 为 `TINYINT(1)` 同义 |
| 定点 / 浮点 | `DECIMAL(10,2)`, `FLOAT`, `DOUBLE` | 金额优先 **`DECIMAL`** |
| 字符串 | `CHAR(n)`, `VARCHAR(n)` | `n` 为字符长度（与字符集有关） |
| 文本 | `TEXT`, `MEDIUMTEXT`, `LONGTEXT` | 大文本，注意行大小与索引限制 |
| 二进制 | `BINARY`, `VARBINARY`, `BLOB` | 存字节流 |
| 时间 | `DATE`, `TIME`, `DATETIME`, `TIMESTAMP` | `TIMESTAMP` 受时区与 `sql_mode` 影响；常用 **`DATETIME(3)`** 存毫秒 |
| JSON | `JSON` | MySQL 5.7+；校验格式，函数查询 |

### 2.3 列选项

- **`NOT NULL`** / **`NULL`**
- **`DEFAULT` 字面量** 或 **`DEFAULT (表达式)`**（MySQL 8.0.13+ 部分类型支持表达式）
- **`AUTO_INCREMENT`**：仅适用于整数主键/唯一键列，表中通常只有一个
- **`COMMENT '...'`** 注释

---

## 三、约束

| 约束 | 说明 |
| --- | --- |
| **`PRIMARY KEY`** | 非空且唯一；InnoDB 聚簇索引按主键组织 |
| **`UNIQUE`** | 唯一，允许多个 `NULL`（旧行为与引擎有关，以文档为准） |
| **`NOT NULL`** | 非空 |
| **`CHECK (expr)`** | MySQL **8.0.16+** 起强制；之前版本解析但可能不生效 |
| **`FOREIGN KEY`** | 引用父表列；要求类型/字符集兼容；InnoDB 支持 |

命名外键便于删除：

```sql
ALTER TABLE orders
  ADD CONSTRAINT fk_orders_user
  FOREIGN KEY (user_id) REFERENCES users (id)
  ON DELETE RESTRICT
  ON UPDATE CASCADE;
```

```sql
ALTER TABLE orders DROP FOREIGN KEY fk_orders_user;
```

---

## 四、主键、外键与索引（表内对象）

- **主键**：一张表一个；常为单列 `BIGINT` 自增或业务无关代理键。
- **外键**：保证引用完整性；注意 **级联**（`ON DELETE` / `ON UPDATE`）对数据的影响。
- **索引**：普通索引、唯一索引、联合索引、前缀索引（`VARCHAR(100)` 上 `KEY x (col(20))`）等。

在 `CREATE TABLE` 或 `ALTER TABLE` 中维护：

```sql
ALTER TABLE orders ADD INDEX idx_created (created_at);

ALTER TABLE orders DROP INDEX idx_created;

CREATE UNIQUE INDEX uq_orders_ext ON orders (user_id, status);
```

**设计要点**：联合索引列顺序影响「最左前缀」能否命中；深度调优见 [index.md](../index.md)。

---

## 五、列的添加、删除与更改

### 5.1 添加列

```sql
ALTER TABLE orders
  ADD COLUMN remark VARCHAR(255) NULL AFTER status;
```

### 5.2 删除列

```sql
ALTER TABLE orders DROP COLUMN remark;
```

若列被外键、索引、视图引用，需先处理依赖。

### 5.3 更改列类型 / 约束（不改名）

```sql
ALTER TABLE orders
  MODIFY COLUMN status VARCHAR(32) NOT NULL DEFAULT 'pending';
```

### 5.4 更改列名（可同时改类型）

```sql
-- 旧名 -> 新名，必须写全列定义
ALTER TABLE orders
  CHANGE COLUMN status order_status VARCHAR(16) NOT NULL DEFAULT 'pending';
```

MySQL 8.0+ 仅改名可用：

```sql
ALTER TABLE orders RENAME COLUMN status TO order_status;
```

---

## 六、实战提示

- 大表 `ALTER` 前在从库或备份环境验证执行时间与锁行为。
- 字符集统一 **`utf8mb4`**，排序规则按是否需要大小写/口音敏感选择（如 `_ci` vs `_bin`）。
- 外键与 `ON DELETE CASCADE` 会级联删除子表行，设计时明确业务语义。
- 与权限、备份相关操作仍见 [sql.md](../sql.md)。
