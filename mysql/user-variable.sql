-- 用户变量
-- 1. 使用SET语句为用户变量赋值 `:=` 也可以用 `=`
SET @film := (SELECT title FROM film WHERE film_id = 1);
SET @film = (SELECT title FROM film WHERE film_id = 1);

-- 2. 使用INTO在查询中为用户变量赋值
SELECT title INTO @film FROM film WHERE film_id = 1;

-- 3. 使用用户变量在查询中 不建议再用
SELECT @film := title FROM film WHERE film_id = 1;

SELECT @film AS film_title;
SELECT @film title;

-- SET 是 SELECT INTO 的简写