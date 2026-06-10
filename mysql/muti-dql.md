<!-- 隐式内连接 -->
select 字段列表 from 表1, 表2 where 条件;
<!-- 显式内连接 -->
select 字段列表 from 表1 [inner] join 表2 on 连接条件;
<!-- 左连接 完全包含左表 -->
select 字段列表 from 表1 left [outer] join 表2 on 连接条件;
<!-- 右连接 -->
select 字段列表 from 表1 right [outer] join 表2 on 连接条件;

<!-- 子查询 嵌套查询 外层语句可以是select,insert,update, delete -->
select * from t1 where column1 = (select colum1 from t2 ...)

<!-- 依据返回结果分类 -->
1. 标量子查询 单值 常用操作符: >, <, =, >=, <=
2. 列子查询   常用操作符: in, not in
3. 行子查询   常用操作符: =, <>, in, not in
4. 表子查询  临时表  常用操作符: in

