# 多表设计核心内容总结

多表设计的目标是：既保证数据一致性，又兼顾查询性能和可维护性。

## 1. 先明确业务实体与关系

多表设计第一步是把业务对象抽象成实体，再定义关系类型：

- 一对一（1:1）：用户与用户详情。
- 一对多（1:N）：用户与订单。
- 多对多（M:N）：学生与课程（需要中间表）。

建议先画简单 ER 图，再落到表结构。

## 2. 主键与外键设计

### 主键（PK）
- 每张表必须有稳定主键，常见用 `BIGINT` 自增或雪花 ID。
- 主键应尽量短、不可变、无业务含义（避免后续变更代价大）。

### 外键（FK）
- 外键用于表达表之间的引用关系，保证引用完整性。
- 核心原则：子表记录必须引用父表存在的记录。

示例（1:N）：

```sql
CREATE TABLE users (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  name VARCHAR(100) NOT NULL
);

CREATE TABLE orders (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  total_amount DECIMAL(10,2) NOT NULL,
  CONSTRAINT fk_orders_user
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

## 3. 范式与反范式平衡

### 常见范式目标
- 1NF：字段原子化，不存数组/拼接值。
- 2NF：消除对联合主键的部分依赖。
- 3NF：消除传递依赖，非主键只依赖主键。

### 反范式
- 在高并发读场景下，允许适度冗余（如保存 `user_name_snapshot`），减少联表成本。
- 冗余必须有同步策略（应用层、消息、定时修复）。

## 4. 多对多必须使用关联表

不要在一个字段里存“逗号分隔 ID”，应使用关联表：

```sql
CREATE TABLE student_course (
  student_id BIGINT NOT NULL,
  course_id BIGINT NOT NULL,
  enrolled_at DATETIME NOT NULL,
  PRIMARY KEY (student_id, course_id)
);
```

如需扩展关系属性（状态、成绩、创建时间），也应放在关联表。

## 5. 索引设计（多表场景关键）

- 所有外键列建议建索引（如 `orders.user_id`）。
- 高频查询条件列、排序列、连接列建立联合索引。
- 联合索引遵循最左前缀原则，按“过滤度高 + 常用查询顺序”设计。

示例：

```sql
CREATE INDEX idx_orders_user_ctime ON orders(user_id, created_at);
```

## 6. 典型查询写法与原则

- 先过滤再关联：尽量在子查询或主表先 `WHERE` 缩小数据集。
- 明确字段列表：避免 `SELECT *`。
- 保证分页稳定：`ORDER BY created_at DESC, id DESC`。
- 用 `EXPLAIN` 检查执行计划，避免全表扫描和临时文件排序。

## 7. 级联策略与数据生命周期

外键常见策略：

- `ON DELETE RESTRICT`：禁止删除被引用父数据（默认安全）。
- `ON DELETE CASCADE`：删除父数据时联动删除子数据（谨慎使用）。
- `ON DELETE SET NULL`：父数据删除后子表置空（需允许 NULL）。

生产建议：删除策略先按“安全优先”，高风险级联删除要做评审。

## 8. 常见设计误区

- 把多值塞进一个字段（破坏范式，难查询）。
- 外键列不建索引（联表慢、锁冲突更明显）。
- 主键使用有业务语义且会变化的字段（后期迁移复杂）。
- 过早做过度分表（维护成本高，收益不明显）。
- 只关注建表不关注查询路径（上线后性能问题集中爆发）。

## 9. 实战检查清单

1. 实体和关系是否完整（1:1 / 1:N / M:N）？
2. 每张表是否有稳定主键？
3. 外键与约束是否明确？
4. 高频查询路径是否有对应索引？
5. 是否存在不必要冗余或无法维护的冗余？
6. 是否为删除/归档定义了生命周期策略？

> 一句话：多表设计不是“拆得越细越好”，而是在一致性、性能、演进成本之间做平衡。
