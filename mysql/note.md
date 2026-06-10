# MySQL

```bash
docker exec -it mysql -uroot -p
mysql -h 192.168.1.9 -P 3306 -uking -p
```

```sql
-- 查看版本
select @@version;

-- 查看数据目录
select @@datadir;
-- 底层监控
SELECT * FROM performance_schema.users;
SELECT user, host, total_connections AS cxns FROM performance_schema.accounts ORDER BY cxns DESC;

-- 查看当前活动数据库
select database();
show databases;
use test;
show tables;
-- 查看表结构
show columns from actor;
describe actor;
desc actor;
select * from actor;
```

```sql
-- MySQL 8.0 特有表示法
DEFAULT_GENERATED
```

EER图

- 属性和关系继承
- 类别或联合类型
- 特化和概括
- 子类和超类

```bash
wget https://downloads.mysql.com/docs/sakila-db.tar.gz
curl -O https://downloads.mysql.com/docs/sakila-db.tar.gz
tar -xvzf sakila-db.tar.gz
mysql -uroot -p < sakila-db/sakila-schema.sql
mysql -uroot -p < sakila-db/sakila-data.sql
```

## 比较运算符

不等于：`<>` 或 `!=`
NULL 值：`IS NULL` 或 `IS NOT NULL`
范围：`BETWEEN ... AND ...`
集合：`IN (...)` 或 `NOT IN (...)`
模式匹配：`LIKE` 或 `NOT LIKE`（支持 `%` 和 `_` 通配符）
正则表达式：`REGEXP` 或 `NOT REGEXP`
逻辑运算符：`AND`、`OR`、`NOT`
优先级：`NOT` > `AND` > `OR`

默认情况下，字符串比较不区分大小写，而且使用当前字符集。可以使用 `BINARY` 关键字进行区分大小写的比较。
`%` 匹配任意字符序列（包括空序列），`_` 匹配单个字符。应避免在模式开头使用 `%`，以便利用索引。

```sql
SHOW TABLE STATUS;
```

使用AND、OR、NOT和XOR合并条件。
不能依赖SQL的默认优先级，建议使用括号明确优先级。

!=、<>、NOT的区别
`!=` 和 `<>` 都表示“不等于”，是等价的，可以互换使用。
`NOT` 是一个逻辑运算符，用于取反一个条件表达式，可用于 NOT IN、NOT LIKE、NOT BETWEEN 等。
`NOT` 不能单独表示“不等于”，必须与其他比较运算符结合使用。

## 运算符优先级

1. `INTERVAL`
2. `BINARY`, `COLLATE`
3. `!` (NOT)
4. `-` (负号), `~` (按位取反)
5. `^` (按位异或)
6. `*`, `/`, `%`、`DIV`、`MOD` (乘、除、取余)
7. `+`, `-` (加、减)
8. `<<`, `>>` (位移)
9. `&` (按位与)
10. `|` (按位或)
11. `=`, `<=>`, `>=`, `>`, `<=`, `<`, `<`, `<>`, `!=`, `IS`, `LIKE`, `REGEXP`, `IN`,`MEMBER OF`, `SOUNDS LIKE`
12. `BETWEEN`, `CASE`, `WHEN`, `THEN`, `ELSE`
13. `NOT`
14. `AND`, `&&`
15. `XOR`
16. `OR`, `||`
17. `=` (赋值), `:=` (赋值)

## SOUNDS LIKE 运算符

- `SOUNDS LIKE`：用于比较两个字符串的发音是否相似（基于 SOUNDEX 算法）

    ```sql
    SELECT 'hello' SOUNDS LIKE 'hallo';  -- 返回 1，表示发音相似
    SELECT 'hello' SOUNDS LIKE 'world';  -- 返回 0，表示发音不相似
    ```

  - 适用于英文发音相近的模糊匹配，中文无效。
  - 实际底层等价于 `SOUNDEX(str1) = SOUNDEX(str2)`

## `=`与``:=的区别

- `=`：用于比较和赋值，在WHERE、ON、SELECT等语句中表示“等于”比较；在SET语句中，也可用于变量赋值（但推荐用 :=）。
- `:=`：只用于给变量赋值，不能用于比较，常用于存储过程和函数中。

## 变量

- 用户变量：以 `@` 开头，作用域为当前会话，存储临时数据

    ```sql
    SET @var1 = 10;
    SELECT @var1;  -- 返回 10
    ```

## ORDER BY子句

- 用于对查询结果进行排序，默认升序排列（ASC），可指定降序排列（DESC）。
- 可以按多个列排序，优先级从左到右。
- 默认情况下，排序不区分大小写。可以使用 `BINARY` 关键字进行区分大小写的排序。
- 字符串的排序遵循当前字符集和排序规则。

```sql
