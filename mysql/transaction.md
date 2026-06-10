# MySQL 与 InnoDB 事务笔记

事务是数据库里的一组操作，作为一个**逻辑工作单元**执行：要么全部提交成功，要么全部回滚，对外不暴露中间状态。

典型例子是转账：扣款与加款必须同时成功或同时失败，不能只完成一半。

---

## 目录

1. ACID 特性  
2. 基本语法与会话  
3. 并发下的三类读问题  
4. 隔离级别  
5. InnoDB 的 undo、redo 与 MVCC  
6. InnoDB 锁  
7. 死锁  
8. 分布式事务简介  
9. 实践建议  
10. 速查  

---

## 1. ACID 特性

| 字母 | 名称 | 含义 | 常见实现思路 |
|------|------|------|----------------|
| A | 原子性（Atomicity） | 全部成功或全部回滚 | undo log |
| C | 一致性（Consistency） | 约束与业务规则不被破坏 | 由 A、I、D 与业务共同保证 |
| I | 隔离性（Isolation） | 并发事务互不干扰 | 锁 + MVCC |
| D | 持久性（Durability） | 提交后崩溃仍可恢复 | redo log（WAL） |

一致性（C）更多是目标；原子性、隔离性、持久性是工程上常用的手段。

---

## 2. 基本语法与会话

开启、提交、回滚与保存点：

```sql
BEGIN;
-- 或
START TRANSACTION;

COMMIT;
ROLLBACK;

SAVEPOINT point1;
ROLLBACK TO SAVEPOINT point1;
RELEASE SAVEPOINT point1;
```

自动提交与会话变量：

```sql
SHOW VARIABLES LIKE 'autocommit';
SET autocommit = 0;
```

说明：

- `autocommit`、`BEGIN`、`START TRANSACTION` 等均作用于**当前会话**；`SET GLOBAL` 影响新连接，已存在连接仍按原设置。
- 使用显式事务时，建议在应用层统一约定：何时 `COMMIT`/`ROLLBACK`，避免依赖隐式提交行为。

---

## 3. 并发下的三类读问题

### 3.1 脏读（Dirty Read）

读到**别的事务尚未提交**的数据；对方若回滚，则读到的是无效数据。

示例：事务 A 更新余额但未提交，事务 B 读到新值；A 回滚后，B 曾读到的值在库中从未成立。

### 3.2 不可重复读（Non-Repeatable Read）

同一事务内**两次读同一行**，结果不一致，通常因中间有别的事务对该行 **UPDATE/DELETE 并已提交**。

### 3.3 幻读（Phantom Read）

同一事务内**两次按条件查询集合**（如范围、COUNT），**行数或集合成员**发生变化，通常因中间有别的事务 **INSERT 并已提交**。

小结：不可重复读侧重**已有行被改/删**；幻读侧重**多出新行**。

---

## 4. 隔离级别

ANSI 定义的四个级别与三类问题的关系（理论模型；具体引擎行为以手册为准）：

| 隔离级别 | 脏读 | 不可重复读 | 幻读 | 并发性能（相对） |
|----------|------|------------|------|------------------|
| 读未提交（Read Uncommitted） | 可能发生 | 可能发生 | 可能发生 | 最高 |
| 读已提交（Read Committed） | 不发生 | 可能发生 | 可能发生 | 较高 |
| 可重复读（Repeatable Read） | 不发生 | 不发生 | 标准定义下仍可能发生；InnoDB 下多数场景可抑制 | 中等 |
| 串行化（Serializable） | 不发生 | 不发生 | 不发生 | 最低 |

InnoDB 默认隔离级别为**可重复读（RR）**。在 RR 下，InnoDB 通过 **MVCC + 间隙锁（Gap Lock）/临键锁（Next-Key Lock）** 等机制，在常见场景下能避免幻读；具体是否与当前 SQL（当前读 / 快照读）有关，需结合执行计划与锁类型理解。

查看与设置（变量名因版本可能为 `tx_isolation`，以实际环境为准）：

```sql
SELECT @@transaction_isolation;

SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
SET GLOBAL TRANSACTION ISOLATION LEVEL READ COMMITTED;
```

---

## 5. InnoDB 的 undo、redo 与 MVCC

### 5.1 undo log

- 保存修改前的数据镜像，用于**回滚**。
- 为 MVCC 提供**历史版本**，形成行的版本链。

### 5.2 redo log

- 记录页的物理修改，采用 **WAL（先写日志再刷脏页）**。
- 崩溃恢复时重放已写入 redo 的已提交变更，保证**持久性**。
- 常见为循环写入的日志文件（如 `ib_logfile0`、`ib_logfile1`）。

简化理解：业务线程先写 redo（顺序写），再异步将缓冲池中的脏页刷到数据文件。

### 5.3 MVCC 与 ReadView

InnoDB 行上除业务列外，还有与事务相关的系统列（概念上常描述为 `trx_id`、`roll_pointer` 等）：最近修改事务 id、回滚指针，与 undo 一起构成**版本链**。

**ReadView（读视图）** 在快照读时用于判断某版本对当前事务是否可见，典型字段含义：

- 活跃事务 id 列表，以及最小/最大事务 id 边界。
- 创建该 ReadView 的事务 id。

沿版本链从新到旧判断可见性的规则可概括为：已提交且不在「未来」、且不属于未提交的并发事务的版本可见。具体边界以官方文档为准。

**RC 与 RR 在 ReadView 上的常见区别**：

| 级别 | ReadView | 效果 |
|------|----------|------|
| 读已提交（RC） | 语句级快照，常表现为每次一致性读可能用新视图 | 更容易看到别事务新提交的数据 |
| 可重复读（RR） | 事务内首次快照读建立视图后复用 | 同一事务内多次读看到一致快照 |

注意：使用 **当前读**（如 `SELECT ... FOR UPDATE`）时走的是锁与最新版本语义，与纯快照读的 MVCC 路径不同。

---

## 6. InnoDB 锁

### 6.1 粒度

- **表锁**：粒度大，并发度低，MyISAM 等场景常见。
- **行锁**：粒度小，InnoDB 在索引记录上加锁，并发度高；无合适索引时可能锁范围变大甚至接近表锁效果。

### 6.2 行锁相关概念（InnoDB）

| 名称 | 作用 |
|------|------|
| 记录锁（Record Lock） | 锁在索引记录上 |
| 间隙锁（Gap Lock） | 锁索引记录之间的间隙，阻塞向间隙插入，用于抑制幻读 |
| 临键锁（Next-Key Lock） | 记录锁 + 左开右闭间隙，InnoDB 在 RR 下对普通索引范围扫描等常用 |
| 插入意向锁（Insert Intention） | INSERT 在间隙上等待与间隙锁协调 |

### 6.3 共享锁与排他锁（示例）

```sql
-- 共享锁（S）：可读，写需等待
SELECT ... LOCK IN SHARE MODE;

-- 排他锁（X）：读写互斥
SELECT ... FOR UPDATE;
```

MySQL 8.0 起 `LOCK IN SHARE MODE` 可用 `FOR SHARE` 语法替代（以版本手册为准）。

---

## 7. 死锁

### 7.1 必要条件（简述）

互斥、占有并等待、不可抢占、循环等待。四者同时满足才可能形成死锁。

### 7.2 InnoDB 的处理

- **死锁检测**：发现环路后选择回滚**代价较小**的事务（如 undo 量较少）。
- **锁等待超时**：`innodb_lock_wait_timeout`（默认 50 秒），超时未获锁会报错。

排查最近一次死锁可查看：

```sql
SHOW ENGINE INNODB STATUS;
```

### 7.3 工程上减少死锁

- 多个事务以**相同顺序**访问表/行，降低循环等待概率。
- **缩短事务**，减少持锁时间；避免在事务内做 RPC、HTTP 等长耗时操作。
- **WHERE 使用索引**，减少锁范围扩大。
- 在业务允许时考虑略低的隔离级别（如 RC）以减少间隙锁带来的阻塞（需接受语义变化并充分测试）。
- 跨服务协调时可结合业务层幂等与分布式锁，降低数据库侧锁竞争。

---

## 8. 分布式事务简介

单机 InnoDB 事务不能保证跨库跨服务的原子性，分布式场景常用以下思路（仅作分类，选型需结合业务与基础设施）。

**两阶段提交（2PC）**

- 一阶段：各参与者预提交并持久化日志，向协调者投票。
- 二阶段：全部同意则提交，否则回滚。
- 缺点：同步阻塞、协调者可用性、极端情况下与参与者日志策略相关的数据一致性问题。

**TCC（Try / Confirm / Cancel）**

- Try：预留资源；Confirm：确认提交；Cancel：释放预留。
- 优点：相对灵活、性能常优于经典 2PC；缺点：业务侵入大，需完善补偿与幂等。

**SAGA**

- 长事务拆成多个本地事务，每步定义**补偿操作**；失败则按逆序补偿。
- 适合流程长、可接受最终一致的业务。

**本地消息表 + 消息队列**

- 本地事务内写业务表与消息表，再异步投递到 MQ，消费者重试保证**最终一致性**。
- 适合对实时强一致要求不高、可异步完成的场景。

---

## 9. 实践建议

**建议**

- 事务尽量短，尽快提交或回滚。
- 高并发写且可接受 RC 语义时，可评估使用读已提交并充分测试（减少间隙锁带来的阻塞，但可见性与幻读语义与 RR 不同）。
- `WHERE` 条件尽量走索引，避免大范围扫描导致锁范围过大。
- 需要部分失败回滚时合理使用 `SAVEPOINT`。
- 捕获异常后显式 `ROLLBACK`，避免连接回到池里时仍处于错误状态。

**避免**

- 在事务内调用外部 HTTP/RPC、大批量用户输入处理等长耗时逻辑。
- 长事务导致 undo 膨胀、锁长时间占用。
- 无索引的范围更新/删除。
- 在事务内执行与当前业务无关的查询，徒增锁与 MVCC 开销。

---

## 10. 速查

| 主题 | 要点 |
|------|------|
| ACID | 原子、一致、隔离、持久 |
| 并发问题 | 脏读、不可重复读、幻读（关注点不同） |
| 隔离级别 | RU → RC → RR → Serializable，隔离递增、默认并发空间通常递减 |
| InnoDB 默认 | RR；当前读配合 Next-Key 等抑制常见幻读 |
| 持久性 | redo log，WAL，崩溃恢复 |
| 原子性 / 回滚 | undo log |
| 隔离实现 | MVCC（快照读）+ 锁（当前读） |
| RC / RR 快照 | RC 常语句级新快照；RR 常事务级复用首次 ReadView |
| 死锁 | 自动检测回滚一方；配合超时与业务层顺序访问 |

---

## 参考

- [MySQL 8.0 Reference Manual — InnoDB and MySQL Transaction Model](https://dev.mysql.com/doc/refman/8.0/en/innodb-transaction-model.html)
- [MySQL 8.0 — SET TRANSACTION](https://dev.mysql.com/doc/refman/8.0/en/set-transaction.html)

版本差异（如 `transaction_isolation` 与旧名 `tx_isolation`、`LOCK IN SHARE MODE` 与 `FOR SHARE`）以当前安装的 MySQL 官方手册为准。
