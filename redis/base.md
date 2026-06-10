# Redis 核心知识点与实践示例

Redis 是一个 **基于内存的数据结构存储系统**，常用作缓存、计数器、分布式锁、排行榜、会话存储和轻量消息队列。

本文档聚焦 **核心机制 + 可运行示例**，按重要性分层：

| 层级 | 内容 | 建议 |
|---|---|---|
| **核心必会** | 数据结构、过期淘汰、缓存问题、持久化概念 | 先掌握 |
| **工程常用** | 分布式锁、限流、主从/集群、Pipeline/Lua | 项目必用 |
| **进阶扩展** | Streams、HyperLogLog、调优、运维排查 | 按需深入 |

---

## 1. Redis 是什么

### 1.1 一句话定位

Redis = **内存中的键值数据库 + 丰富数据结构 + 高并发读写能力**。

它 **不是** 关系型数据库的替代品，而是用来解决：

- 热点数据读太慢 → **缓存**
- 高并发计数 / 限流 → **原子操作**
- 跨进程协调 → **分布式锁**
- 有序集合场景 → **排行榜 / 延时队列**

### 1.2 为什么 Redis 快（核心必会）

| 原因 | 说明 |
|---|---|
| 内存存储 | 读写不走磁盘（持久化是异步/后台） |
| 单线程执行命令 | 避免锁竞争，命令原子性天然成立 |
| I/O 多路复用 | 单线程也能高效处理大量连接 |
| 高效数据结构 | String、Hash、ZSet 等针对场景优化 |

> **注意：** Redis 6+ 网络 I/O、持久化等部分工作会用到多线程，但 **命令执行仍基本是单线程**，所以不会出现多线程并发改同一 key 的竞态。

### 1.3 基本连接示例

```bash
# 启动后连接
redis-cli

# 带密码连接
redis-cli -h 127.0.0.1 -p 6379 -a your_password

# 测试连通
PING
# 返回 PONG
```

---

## 2. Key 设计规范（核心必会）

好的 Key 设计直接影响可维护性和排查效率。

### 2.1 命名规范

- 唯一性
- 可读性
- 灵活性
- 实效性

```txt
业务:模块:标识[:字段]

user:profile:1001
order:detail:20260001
cache:product:1001
lock:order:20260001
rate:api:login:13800138000
rank:game:daily
```

### 2.2 常用 Key 操作

```bash
SET user:1 "Tom"
GET user:1

EXISTS user:1        # 1 存在，0 不存在
DEL user:1
EXPIRE user:1 60     # 60 秒后过期
TTL user:1           # 查看剩余秒数，-1 永不过期，-2 已不存在

TYPE user:1          # 查看数据类型
```

### 2.3 实践建议

- Key 要有 **业务前缀**，避免多项目冲突
- **必须设置 TTL**（除非明确需要永久存储）
- 避免超大 Key（如一个 Hash 存百万字段）
- 生产环境 **禁止 `KEYS *`**，用 `SCAN` 代替

```bash
SCAN 0 MATCH user:* COUNT 100
```

---

## 3. 数据结构（核心必会）

Redis 的价值很大程度来自 **选对数据结构**。

### 3.1 String — 最常用

**适合：** 简单缓存、计数器、分布式锁、限流计数、JSON 字符串

```bash
# 缓存
SET product:1001 '{"name":"iPhone","price":6999}' EX 3600
GET product:1001

# 计数器
INCR page:view:home          # 浏览量 +1
INCRBY user:1001:points 10   # 积分 +10

# 只有不存在时才设置（分布式锁基础）
SET lock:order:1 token_abc NX EX 30

# 批量操作
MSET user:1 "Tom" user:2 "Jerry"
MGET user:1 user:2
```

**应用场景示例：**

```bash
# 短信验证码，5 分钟有效
SET auth:sms:13800138000 834921 EX 300

# 接口限流：每分钟最多 100 次
INCR rate:api:/login:13800138000
EXPIRE rate:api:/login:13800138000 60
```

---

### 3.2 Hash — 存对象

**适合：** 用户信息、商品属性、配置项（字段会单独更新时）

```bash
HSET user:1001 name "Tom" age 18 city "Shanghai"
HGET user:1001 name
HMGET user:1001 name age
HGETALL user:1001

# 字段自增
HINCRBY user:1001 age 1

# 判断字段是否存在
HEXISTS user:1001 email
```

**String vs Hash 怎么选？**

| 场景 | 推荐 |
|---|---|
| 整个对象一起读写 | String（JSON 序列化） |
| 经常只改部分字段 | Hash |
| 需要原子改单个字段 | Hash |

```bash
# String 方式：改一个字段要读-改-写整个 JSON
# Hash 方式：直接改单个字段
HSET user:1001 last_login_at "2026-06-06 10:00:00"
```

---

### 3.3 List — 双端队列

**适合：** 简单队列、最新消息列表、Timeline

```bash
LPUSH queue:email "task1" "task2"
RPOP queue:email

# 阻塞消费（简易消费者）
BLPOP queue:email 10   # 最多等 10 秒

# 保留最新 100 条消息
LPUSH news:feed "msg3" "msg2" "msg1"
LTRIM news:feed 0 99
```

**简单消息队列示例：**

```bash
# 生产者
LPUSH queue:order-pay '{"orderId":"10001"}'

# 消费者
BRPOP queue:order-pay 0
```

> List 适合做 **轻量队列**；需要消费组、ACK、重试时，优先考虑 **Streams** 或专业 MQ。

---

### 3.4 Set — 去重集合

**适合：** 标签、共同好友、点赞用户集合、抽奖去重

```bash
SADD tags:article:1001 redis mysql docker
SMEMBERS tags:article:1001

SISMEMBER tags:article:1001 redis   # 是否点赞/已收藏

# 交集：共同关注
SINTER user:1001:follow user:1002:follow

# 并集 / 差集
SUNION set:a set:b
SDIFF set:a set:b
```

**业务示例：用户是否已签到**

```bash
SADD sign:20260606 user:1001
SISMEMBER sign:20260606 user:1001   # 1=已签到
```

---

### 3.5 Sorted Set（ZSet）— 排行榜核心

**适合：** 排行榜、延时队列、范围查询 + 排序

```bash
ZADD rank:game 100 user:1001 120 user:1002 95 user:1003

# 分数从高到低取 Top 10
ZREVRANGE rank:game 0 9 WITHSCORES

# 查某用户排名（从 0 开始）
ZREVRANK rank:game user:1001

# 加分
ZINCRBY rank:game 5 user:1001

# 按分数范围查
ZRANGEBYSCORE rank:game 100 200 WITHSCORES
```

**延时队列思路：**

```bash
# score = 执行时间戳
ZADD delay:queue 1717650000 "task:pay:10001"

# 取到期任务
ZRANGEBYSCORE delay:queue 0 1717650000 LIMIT 0 1
```

---

### 3.6 扩展结构（了解即可）

| 结构 | 用途 | 示例 |
|---|---|---|
| Bitmap | 签到、在线状态 | `SETBIT sign:202606 5 1` |
| HyperLogLog | 大规模 UV 估算 | `PFADD uv:page:home user:1001` |
| GEO | 附近的人/门店 | `GEOADD stores 121.47 31.23 store:1` |
| Stream | 消费组消息流 | `XADD mq:* * field value` |

---

## 4. 过期与内存淘汰（核心必会）

### 4.1 过期机制

```bash
SET temp:code 123456 EX 300      # 创建时设置 TTL
SETEX temp:code 300 123456       # 等价写法
EXPIRE temp:code 300             # 后续补 TTL
PERSIST temp:code                # 移除过期时间
```

Redis 删除过期 Key 的方式：

- **惰性删除**：访问 Key 时发现过期才删
- **定期删除**：后台周期扫描

### 4.2 内存上限与淘汰策略

配置 `maxmemory` 后，内存满时会按策略淘汰 Key：

| 策略 | 含义 |
|---|---|
| `noeviction` | 不淘汰，写操作报错（默认需警惕） |
| `allkeys-lru` | 所有 Key 中淘汰最近最少使用 |
| `volatile-lru` | 只淘汰设置了 TTL 的 Key 中 LRU |
| `allkeys-lfu` | 按访问频率淘汰（Redis 4+） |
| `volatile-ttl` | 优先淘汰 TTL 更短的 |

**实践建议：**

```conf
maxmemory 2gb
maxmemory-policy allkeys-lru
```

- 纯缓存场景：常用 `allkeys-lru` / `allkeys-lfu`
- 必须明确内存上限，**不要把 Redis 当无限内存**

---

## 5. 缓存实践（核心必会）

### 5.1 标准缓存模式

```txt
读：先查 Redis → 命中返回 → 未命中查 DB → 写回 Redis
写：先写 DB → 再删缓存（推荐）或更新缓存
```

**Python 伪代码示例：**

```python
def get_user(user_id: str):
    key = f"user:profile:{user_id}"

    cached = redis.get(key)
    if cached:
        return json.loads(cached)

    user = db.query("SELECT * FROM users WHERE id = %s", user_id)
    if not user:
        # 防穿透：缓存空值，短 TTL
        redis.set(key, "null", ex=60)
        return None

    redis.set(key, json.dumps(user), ex=3600)
    return user
```

### 5.2 三大经典问题

#### 缓存穿透

**现象：** 查询不存在的数据，缓存和 DB 都没有，请求每次都打到 DB。

**方案：**

```bash
# 1. 缓存空值（短 TTL）
SET cache:user:99999 "null" EX 60

# 2. 接口层参数校验
# 3. 布隆过滤器拦截明显不存在的 ID
```

#### 缓存击穿

**现象：** 热点 Key 过期瞬间，大量请求同时穿透到 DB。

**方案：**

```python
# 互斥锁：只允许一个线程回源
lock_key = f"lock:rebuild:{user_id}"
if redis.set(lock_key, "1", nx=True, ex=10):
    user = load_from_db(user_id)
    redis.set(key, json.dumps(user), ex=3600)
    redis.delete(lock_key)
else:
    time.sleep(0.05)  # 短暂等待后重试读缓存
    return get_user(user_id)
```

#### 缓存雪崩

**现象：** 大量 Key 同时过期，DB 压力陡增。

**方案：**

```python
import random

# TTL 加随机值，避免同一时刻集体失效
ttl = 3600 + random.randint(0, 300)
redis.set(key, value, ex=ttl)
```

### 5.3 缓存一致性（工程常用）

常见策略：**先更新数据库，再删除缓存**

```python
def update_user(user_id, data):
    db.update(user_id, data)
    redis.delete(f"user:profile:{user_id}")
```

| 策略 | 说明 |
|---|---|
| 先删缓存再写 DB | 可能读到旧数据 |
| 先写 DB 再删缓存 | **更常用** |
| 延迟双删 | 删 → 写 DB → sleep → 再删 |
| 订阅 binlog 异步删缓存 | 一致性更强，复杂度高 |

> 大多数业务接受 **最终一致**，关键是明确容忍窗口并做兜底（TTL、回源）。

---

## 6. 分布式锁（工程常用）

### 6.1 基础实现

```bash
# 加锁：NX = not exists，EX = 过期秒数
SET lock:order:10001 uuid_abc123 NX EX 30
```

```python
import uuid

token = str(uuid.uuid4())
ok = redis.set("lock:order:10001", token, nx=True, ex=30)
if not ok:
    raise Exception("获取锁失败")

try:
    process_order()
finally:
    # Lua 保证“比较 token 再删除”的原子性
    lua = """
    if redis.call('GET', KEYS[1]) == ARGV[1] then
        return redis.call('DEL', KEYS[1])
    else
        return 0
    end
    """
    redis.eval(lua, 1, "lock:order:10001", token)
```

### 6.2 必须注意的点

| 问题 | 处理 |
|---|---|
| 锁过期但业务未完成 | Redisson 看门狗自动续期 |
| 误删别人的锁 | value 用唯一 token + Lua 校验删除 |
| 主从切换丢锁 | 高要求场景用 RedLock（有争议）或 etcd/ZK |
| 不可重入 | 需要可重入锁时用成熟库 |

**生产建议：** 优先 **Redisson** / **go-redis lock**，不要手写半成品。

---

## 7. 限流（工程常用）

### 7.1 固定窗口计数

```bash
INCR rate:login:13800138000:2026060610
EXPIRE rate:login:13800138000:2026060610 60
# 超过 100 则拒绝
```

### 7.2 滑动窗口（ZSet 实现）

```bash
# 记录每次请求时间戳
ZADD rate:api:user:1001 1717650000.123 "req1"
ZADD rate:api:user:1001 1717650001.456 "req2"

# 删除 60 秒前的记录
ZREMRANGEBYSCORE rate:api:user:1001 0 (now-60)

# 统计窗口内次数
ZCARD rate:api:user:1001
```

### 7.3 令牌桶 / 漏桶

复杂限流建议用 **Lua 脚本** 保证原子性，或直接用 **Redis Cell** / 网关层限流。

---

## 8. 持久化（核心必会）

Redis 数据在内存，持久化用于 **重启恢复** 和 **备份**。

### 8.1 RDB — 快照

```conf
save 900 1      # 900 秒内至少 1 次写操作
save 300 10
save 60 10000
```

| 优点 | 缺点 |
|---|---|
| 恢复快、文件紧凑 | 可能丢失最后一次快照后的数据 |

```bash
BGSAVE          # 后台生成 RDB
LASTSAVE        # 上次成功快照时间
```

### 8.2 AOF — 命令日志

```conf
appendonly yes
appendfsync everysec   # 每秒 fsync，常用折中
```

| 优点 | 缺点 |
|---|---|
| 数据丢失更少 | 文件更大，恢复较慢 |

```bash
BGREWRITEAOF    # 重写 AOF，压缩体积
```

### 8.3 怎么选

| 场景 | 建议 |
|---|---|
| 纯缓存 | 持久化要求低 |
| 重要数据 / 锁 / 计数 | AOF + RDB 混合 |
| 要求少丢数据 | AOF `appendfsync always`（性能差） |

---

## 9. 高可用与集群（工程常用）

### 9.1 主从复制

```txt
Master（写） ──复制──> Replica（读）
```

```bash
# 从节点配置
REPLICAOF 192.168.1.10 6379

INFO replication
```

**作用：** 读写分离、数据备份、故障切换基础

**注意：** 主从有 **复制延迟**，写后立即读从库可能读到旧数据。

### 9.2 Sentinel — 哨兵

**作用：** 监控主从、自动故障转移、通知客户端新主节点

```txt
Sentinel 1 ─┐
Sentinel 2 ─┼─ 监控 ─> Master + Replicas
Sentinel 3 ─┘
```

- 解决 **高可用**
- **不解决** 数据分片和容量扩展

### 9.3 Redis Cluster — 集群

**作用：** 数据分片（16384 个 hash slot）、横向扩展

```bash
SET user:1001 "Tom"
# 对 key 做 CRC16 算 slot，路由到对应节点

CLUSTER NODES
```

| 方案 | 解决什么 |
|---|---|
| 主从 | 备份、读扩展 |
| Sentinel | 自动故障转移 |
| Cluster | 大数据量、高吞吐分片 |

---

## 10. 事务、Pipeline、Lua（工程常用）

### 10.1 Pipeline — 批量发送，减少 RTT

```python
pipe = redis.pipeline()
pipe.set("key1", "a")
pipe.set("key2", "b")
pipe.incr("counter")
pipe.execute()   # 一次网络往返批量执行
```

> Pipeline 不是事务，中间可能被其他客户端命令插入。

### 10.2 事务 MULTI / EXEC

```bash
MULTI
INCR account:1001:balance
DECR account:1002:balance
EXEC
```

- 保证命令 **按顺序批量执行**
- **不是** 关系型数据库那种可回滚事务
- `DISCARD` 取消，`WATCH key` 实现乐观锁（key 被改则 EXEC 失败）

### 10.3 Lua — 原子执行多条命令（推荐）

**扣库存示例：**

```lua
-- KEYS[1] = stock:1001, ARGV[1] = 扣减数量
local stock = tonumber(redis.call('GET', KEYS[1]))
local num = tonumber(ARGV[1])
if stock == nil or stock < num then
  return 0
end
redis.call('DECRBY', KEYS[1], num)
return 1
```

```bash
EVAL "脚本内容" 1 stock:1001 1
```

**适用：** 分布式锁释放、限流、库存扣减、原子 check-and-set

---

## 11. 典型业务示例

### 11.1 排行榜

```bash
# 更新分数
ZINCRBY rank:weekly 10 user:1001

# Top 10
ZREVRANGE rank:weekly 0 9 WITHSCORES

# 我的排名
ZREVRANK rank:weekly user:1001
```

### 11.2 点赞 / 收藏

```bash
SADD like:article:1001 user:2001
SISMEMBER like:article:1001 user:2001
SCARD like:article:1001
```

### 11.3 Session / Token

```bash
SET session:abc123 '{"userId":1001,"role":"admin"}' EX 7200
GET session:abc123

# 登出 / 拉黑 Token
DEL session:abc123
SADD token:blacklist jti_xxx
```

### 11.4 附近门店（GEO）

```bash
GEOADD stores 121.4737 31.2304 store:1 121.4800 31.2400 store:2
GEORADIUS stores 121.47 31.23 5 km WITHDIST ASC COUNT 10
```

---

## 12. 性能与运维（进阶）

### 12.1 常见性能问题

| 问题 | 表现 | 处理 |
|---|---|---|
| 大 Key | 删除/读取阻塞 | 拆分、Hash 分片 |
| 热 Key | 单节点 QPS 过高 | 本地缓存、多副本、Key 分散 |
| 慢命令 | 延迟飙升 | 避免 `KEYS`、大集合 `SMEMBERS` |
| 阻塞命令 | `BLPOP` 还好，`FLUSHALL` 危险 | 用 `SCAN`、异步删除 |

### 12.2 排查命令

```bash
SLOWLOG GET 10          # 慢查询
INFO memory             # 内存使用
INFO stats              # 命中率等
MEMORY USAGE key:xxx    # 单 Key 内存
CLIENT LIST             # 连接数
```

### 12.3 生产禁忌

- `KEYS *` 在线上扫全库
- 无 TTL 的永久 Key 无限增长
- 把 Redis 当唯一数据源却不持久化
- 从库读要求强一致却不走主库

---

## 13. 速查：命令与场景对照

| 需求 | 数据结构 | 核心命令 |
|---|---|---|
| 缓存 JSON | String | `SET` / `GET` + `EX` |
| 对象字段 | Hash | `HSET` / `HGET` / `HGETALL` |
| 简单队列 | List | `LPUSH` / `BRPOP` |
| 去重 / 标签 | Set | `SADD` / `SISMEMBER` |
| 排行榜 | ZSet | `ZADD` / `ZREVRANGE` |
| 计数器 | String | `INCR` / `INCRBY` |
| 分布式锁 | String | `SET NX EX` + Lua 解锁 |
| 延时任务 | ZSet | score=时间戳 |
| 限流 | String / ZSet | `INCR` / ZSet 滑动窗口 |

---

## 14. 学习路径建议

```txt
第 1 步：String / Hash / ZSet + TTL + 缓存读写
第 2 步：缓存穿透 / 击穿 / 雪崩 + 一致性策略
第 3 步：分布式锁 + 限流 + Lua 原子操作
第 4 步：RDB / AOF + 主从 + Sentinel / Cluster 概念
第 5 步：慢查询、大 Key、热 Key 排查与治理
```

---

## 15. 总结

Redis 的核心不是记命令，而是：

1. **选对数据结构**
2. **设好 TTL 和内存策略**
3. **理解单线程 + 原子性**
4. **把缓存一致性、锁、限流当成工程问题**
5. **知道高可用方案各自解决什么**

把 Redis 用在 **热点、临时态、高并发协调** 上，而不是替代 MySQL 做所有持久化业务，才算真正用好 Redis。