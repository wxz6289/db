# 数据库表操作与约束

## 1. 表的基本操作

### 创建表（CREATE TABLE）

**语法**：
```sql
CREATE TABLE 表名 (
  列名1 数据类型 [约束],
  列名2 数据类型 [约束],
  ...
  [表级约束]
);
```

**示例**：
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50) NOT NULL,
  email VARCHAR(100) UNIQUE,
  age INT DEFAULT 18,
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```


### 修改表（ALTER TABLE）

- **添加列**：
  ```sql
  ALTER TABLE 表名 ADD 列名 数据类型 [约束];
  ```

- **删除列**：
  ```sql
  ALTER TABLE 表名 DROP 列名;
  ```

- **修改列类型**：
  ```sql
  ALTER TABLE 表名 MODIFY 列名 新数据类型;
  ```

- **重命名列**：
  ```sql
  ALTER TABLE 表名 CHANGE 旧列名 新列名 数据类型;
  ```

- **重命名表**：
  ```sql
  ALTER TABLE 旧表名 RENAME TO 新表名;
  ```

- **添加约束**：
  ```sql
  ALTER TABLE 表名 ADD CONSTRAINT 约束名 约束类型(列);
  ```


### 删除表（DROP TABLE）

- **删除单个表**：
  ```sql
  DROP TABLE 表名;
  ```

- **删除多个表**：
  ```sql
  DROP TABLE 表1, 表2, ...;
  ```

- **安全删除**（表不存在不报错）：
  ```sql
  DROP TABLE IF EXISTS 表名;
  ```


### 清空表（TRUNCATE TABLE）

```sql
TRUNCATE TABLE 表名;
```

**说明**：删除所有数据，但保留表结构；速度快。


### 复制表

- **仅复制结构**：
  ```sql
  CREATE TABLE 新表 LIKE 原表;
  ```

- **复制结构和数据**：
  ```sql
  CREATE TABLE 新表 AS SELECT * FROM 原表;
  ```

- **仅复制部分数据**：
  ```sql
  CREATE TABLE 新表 AS SELECT * FROM 原表 WHERE 条件;
  ```


## 2. 表的常见约束

### 主键约束（PRIMARY KEY）

**特点**：
- 唯一标识每行，且不能为 NULL
- 一个表只能有一个主键
- 性能最好，常用作查询条件

**示例**：
```sql
CREATE TABLE users (
  id INT PRIMARY KEY,
  name VARCHAR(50)
);
```

**或在表定义后添加**：
```sql
ALTER TABLE users ADD PRIMARY KEY (id);
```


### 唯一约束（UNIQUE）

**特点**：
- 保证列值唯一，但可以有多个 NULL
- 一个表可有多个唯一约束

**示例**：
```sql
CREATE TABLE users (
  id INT,
  email VARCHAR(100) UNIQUE,
  username VARCHAR(50) UNIQUE NOT NULL
);
```

```

### 非空约束（NOT NULL）

**说明**：列必须有值，不能为 NULL

**示例**：
```sql
CREATE TABLE users (
  id INT NOT NULL,
  name VARCHAR(50) NOT NULL
);
```

### 默认值约束（DEFAULT）

**说明**：插入数据时若不指定值，使用默认值

**示例**：
```sql
CREATE TABLE users (
  id INT,
  age INT DEFAULT 18,
  status VARCHAR(20) DEFAULT 'active',
  create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

### 外键约束（FOREIGN KEY）

**特点**：
- 维护表间关系，保证数据一致性
- 被引用表的列必须是唯一的（通常是主键）

**示例**：
```sql
CREATE TABLE orders (
  order_id INT PRIMARY KEY,
  user_id INT,
  FOREIGN KEY (user_id) REFERENCES users(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
);
```

**或在表定义后添加**：
```sql
ALTER TABLE orders ADD CONSTRAINT fk_user
  FOREIGN KEY (user_id) REFERENCES users(id);
```


### 检查约束（CHECK）

**说明**：限制列值必须满足特定条件

**示例**：
```sql
CREATE TABLE users (
  id INT,
  age INT CHECK (age >= 18 AND age <= 120),
  gender VARCHAR(10) CHECK (gender IN ('男', '女', '其他'))
);
```


### 自增约束（AUTO_INCREMENT）

**特点**：
- 每插入新行时自动按序递增
- 通常与主键配合使用

**示例**：
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(50)
);
```

**指定初始值**：
```sql
ALTER TABLE users AUTO_INCREMENT = 100;
```

## 3. 数据类型

### 数字类型

- `INT`：整数（-2^31 ~ 2^31-1）
- `BIGINT`：大整数
- `DECIMAL(总位数, 小数位数)`：精确小数
- `FLOAT` / `DOUBLE`：浮点数

### 字符串类型

- `VARCHAR(长度)`：可变长度字符串（推荐）
- `CHAR(长度)`：固定长度字符串
- `TEXT`：大型文本

### 日期时间类型

- `DATE`：日期（YYYY-MM-DD）
- `TIME`：时间（HH:MM:SS）
- `DATETIME`：日期时间
- `TIMESTAMP`：时间戳（自动记录修改时间）

### 其他类型

- `BOOLEAN`：布尔值（0 或 1）
- `BLOB`：二进制数据
- `JSON`：JSON 数据（MySQL 5.7+）


## 4. 表操作的实战要点

### 规范建议

- 每个表都应该有主键
- 使用 `VARCHAR` 而不是 `CHAR`（节省空间）
- 使用 `TIMESTAMP DEFAULT CURRENT_TIMESTAMP` 记录创建/修改时间
- 外键关联时明确指定级联策略（CASCADE / SET NULL / RESTRICT）
- 对经常查询的列创建索引

### 常见错误

- 删除存在外键约束的表会失败
- 主键冲突导致插入失败
- 忘记设置 NOT NULL 就插入了 NULL 导致数据不合规
- 修改表结构时阻塞业务（大表需谨慎）

### 生产环境建议

- 结构变更前必须备份
- 大表修改使用在线 DDL 工具
- 外键约束要平衡数据一致性与性能
- 定期检查表结构和索引使用情况


## 5. 表的查询与维护

### 查看表信息

- **查看所有表**：
  ```sql
  SHOW TABLES;
  ```

- **查看表结构**：
  ```sql
  DESCRIBE 表名;
  DESC 表名;
  ```
  或
  ```sql
  SHOW COLUMNS FROM 表名;
  ```

- **查看创建语句**：
  ```sql
  SHOW CREATE TABLE 表名;
  ```

- **查看表统计信息**：
  ```sql
  SELECT * FROM information_schema.TABLES WHERE TABLE_NAME='表名';
  ```

### 表维护

- **优化表**（MySQL）：
  ```sql
  OPTIMIZE TABLE 表名;
  ```

- **检查表**：
  ```sql
  CHECK TABLE 表名;
  ```

- **修复表**：
  ```sql
  REPAIR TABLE 表名;
  ```

> 表是数据库的核心，合理设计表结构、选择约束类型直接影响数据质量和查询性能。
