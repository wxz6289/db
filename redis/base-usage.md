```bash
-- string
set user:001 King;

get "user:001"

exists user:001

expire user:001 100

ttl user:001

type user:001

del user:001

ping

keys *

get user:002

scan 0 match  user:001 count 100

set user:002 zpp

set user:002 30
get user:002

setex user:001 100 man

setnx user:001 dreamer
get user:002
incr user:002
incrby user:002 12
keys *

mset user:001 king  user:003 wxz user:004 xiaohong

mget user:001 user:002 user:003

keys *
append user:005

get user:002

setrange user:002 offset 43

-- hash
hset user:100 name King age 20

hget all user:100

hget user:100 name

hexists user:100 sex
hdel user:100 age

hget user:100 name
hset user:100 age 32

hlen user:100
hvals user:100
hkeys user:100
hgetall user:100
hincrby user:100 age 2
hget user:100 age

keys *

-- List

rpush user:hobby python java
lrange user:hobby 0 3
lrange user:hobby 0 -1

lpush user:hobby js

lpop user:hobby
rpop user:hobby
llen user:hobby

linsert user:hobby before python java
linsert user:hobby after python rust
lset user:hobby 0 kotlin

lrem user:hobby 2 rust
ltrim user:hobby 3 5
lindex  user:hobby 1

-- set 唯一 无序

sadd myset a b c
smembers myset4
sadd myset b c a d
srem myset c d
spop myset 2

sadd myset2 d a g h

sdiff myset myset2
sdiffstore myset4 myset myset2

sinter myset myset2
sunion myset myset2
sinterstore myset1 myset myset2
sunionstore myset3 myset myset2

smembers  myset2
smove myset2 myset g
sismember myset h
srandmember myset 2
smembers  myset

-- sorted set
zadd players 3000 a 3000 b 3000 c
zrange players 0 -1
zrange  players 0 -1 withscores
zincrby players 600 c
zrevrange players 0 -1 withscores
zrank players c
zrevrank players b
zcard players

zrangebyscore players 3200 3600 withscores
zrevrangebyscore  players  3400 3000 withscores
zrem players b
zrange players 0 -1 withscores
zadd players 3300 a 3500 d 6000 b 8100 d

zremrangebyrank players 0 2

zcount players 6000 8000


keys user:*
exists user:001
expire user:001 2
persist user:001
-- 切换数据库
select 0

keys *

move user:001 1

randomkey
-- 重命名key
rename user:002 u:001
get user:002
get u:001

echo "hello redis"
dbsize
info
-- 查看所有redis配置
config get *

-- 请空当前数据库
flushdb

-- 请空所有数据库
flushall
```
