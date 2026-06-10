SELECT CONCAT(first_name, ' ', last_name, ' played in ', title) AS movie FROM actor JOIN film_actor USING (actor_id) JOIN film USING (film_id)
 ORDER BY movie LIMIT 10;


-- 列别名使用位置有限制，不能在WHERE、USING、ON子句中使用(语句执行前不总能确定值),可以在GROUP BY、HAVING、ORDER BY、LIMIT子句中使用
-- 别名长度最多为255个字符,可以包含任意字符,如果包含空格或特殊字符,必须用反引号(`)括起来
-- 别名在所有平台均不区分大小写

SELECT first_name AS name FROM actor WHERE name = 'PENELOPE';

SELECT actor_id AS id FROM actor WHERE first_name = 'ZERO';
-- AS 可省略 但建议保留以明确分别列别名，尤其在以逗号分隔的多列中
SELECT actor_id id FROM actor WHERE first_name = 'ZERO';

-- 表别名可以在任何地方使用,包括WHERE、USING、ON子句中
-- 表别名创建后不使用表别名无法引用表
SELECT ac.actor_id, ac.first_name, ac.last_name, fl.title FROM actor ac INNER JOIN film_actor fa ON ac.actor_id = fa.actor_id JOIN film fl ON fa.film_id = fl.film_id WHERE fl.title = 'AFFAIR PREJUDICE';

SELECT ac.actor_id, ac.first_name, ac.last_name, fl.title FROM actor ac INNER JOIN film_actor fa USING(actor_id) JOIN film fl USING(film_id) WHERE fl.title = 'AFFAIR PREJUDICE';

-- 使用别名后必须使用别名
SELECT ac.actor_id, ac.first_name, ac.last_name, fl.title FROM actor ac INNER JOIN film_actor fa USING(actor_id) JOIN film fl USING(film_id) WHERE film.title = 'AFFAIR PREJUDICE';

-- 检查同名电影
SELECT fm1.film_id, fm1.title FROM film AS fm1, film AS fm2  WHERE fm1.title = fm2.title AND fm1.film_id <> fm2.film_id;

-- distinct 关键字 去掉重复行
SELECT DISTINCT first_name FROM actor JOIN film_actor USING(actor_id);
-- 不当使用distinct查询结果不正确
SELECT DISTINCT first_name, last_name FROM actor JOIN film_actor USING(actor_id);

SELECT DISTINCT CONCAT(first_name, ' ', last_name) as name FROM actor JOIN film_actor USING(actor_id) ORDER BY name;

SELECT first_name FROM actor WHERE first_name IN ("GENE", "MARY", "JOHNNY");

SELECT first_name FROM actor WHERE first_name IN ("GENE", "MARY", "JOHNNY") GROUP BY first_name;

SELECT first_name FROM actor WHERE first_name GROUP BY first_name;

-- 聚集语句
-- COUNT() 计算行数
SELECT COUNT(*) FROM actor;
SELECT COUNT(DISTINCT first_name) as unique_first_names FROM actor;
SELECT COUNT(*) FROM customer;
SELECT COUNT(email) FROM customer;
SELECT COUNT(DISTINCT email) FROM customer;

-- SUM() 计算总和
SELECT SUM(cost) FROM house_price GROUP BY city;

-- AVG() 计算平均值
SELECT AVG(cost) FROM house_price GROUP BY city;

-- MAX()/MIN() 计算分组中的最值
SELECT MAX(cost) FROM house_price GROUP BY city;
SELECT MIN(cost) FROM house_price GROUP BY city;

-- STD()(MySQL扩展) / STDDEV()(兼容Oracle) / STDDEV_POP() (标准SQL) / STDDEV_SAMP() 计算分组中行内值的标准差

-- HAVING 子句 用于过滤分组 having子句必须包含select子句中列出的表达式或列。
SELECT first_name, last_name, COUNT(film_id) FROM actor JOIN film_actor USING(actor_id) GROUP BY actor_id, first_name, last_name HAVING COUNT(film_id) > 40 ORDER BY COUNT(film_id) DESC;

SELECT first_name, last_name, COUNT(film_id) as cnt FROM actor JOIN film_actor USING(actor_id) GROUP BY actor_id, first_name, last_name HAVING cnt > 40 ORDER BY cnt DESC;


SELECT title, COUNT(rental_id) as num_rented FROM film INNER JOIN inventory USING(film_id)  INNER JOIN rental USING(inventory_id) GROUP BY title HAVING num_rented > 30 ORDER BY num_rented DESC LIMIT 5;

-- 结果正确但使用不当, 数据较多时效率低 having子句应决定使用哪些行构成分组
SELECT first_name, last_name, COUNT(film_id) as cnt FROM actor INNER JOIN film_actor USING(actor_id) GROUP BY actor_id, first_name, last_name HAVING first_name = 'EMILY' AND last_name = 'DEE';

SELECT first_name, last_name, COUNT(film_id) as cnt FROM actor INNER JOIN film_actor USING(actor_id) WHERE first_name = 'EMILY' AND last_name = 'DEE' GROUP BY actor_id, first_name, last_name;

SELECT first_name, last_name, film_id FROM actor INNER JOIN film_actor USING(actor_id) LIMIT 20;

-- UNION 操作符 合并两个或多个SELECT语句的结果集
SELECT first_name FROM actor
UNION
SELECT first_name FROM customer
UNION
SELECT title FROM film;

SELECT COUNT(*) AS total_count FROM (
  SELECT first_name FROM actor
  UNION
  SELECT first_name FROM customer
  UNION
  SELECT title FROM film
) AS combined;

SELECT
  (SELECT COUNT(*) FROM actor) AS actor_num,
  (SELECT COUNT(*) FROM customer) AS customer_num,
  (SELECT COUNT(*) FROM film) AS film_num;


SELECT
  (SELECT COUNT(first_name) FROM actor) AS actor_num,
  (SELECT COUNT(first_name) FROM customer) AS customer_num,
  (SELECT COUNT(title) FROM film) AS film_num;

SELECT
  (SELECT COUNT(first_name) FROM actor) +
  (SELECT COUNT(first_name) FROM customer) +
  (SELECT COUNT(title) FROM film) AS total_count;


SELECT title, COUNT(rental_id) AS num_rented FROM film INNER JOIN inventory USING(film_id)  INNER JOIN rental USING(inventory_id) GROUP BY title ORDER BY num_rented DESC LIMIT 5;

SELECT title, COUNT(rental_id) AS num_rented FROM film INNER JOIN inventory USING(film_id)  INNER JOIN rental USING(inventory_id) GROUP BY title ORDER BY num_rented ASC LIMIT 5;

-- 查询租赁次数最多和最少的5部电影
(SELECT title, COUNT(rental_id) AS num_rented FROM film INNER JOIN inventory USING(film_id)  INNER JOIN rental USING(inventory_id) GROUP BY title ORDER BY num_rented DESC LIMIT 5)
UNION
(SELECT title, COUNT(rental_id) AS num_rented FROM film INNER JOIN inventory USING(film_id)  INNER JOIN rental USING(inventory_id) GROUP BY title ORDER BY num_rented ASC LIMIT 5);

-- UNION限制 1. 输出标注使用第一个SELECT语句的列名或表达式的名称 2. 每个SELECT语句的列数必须相同 3. 每个SELECT语句对应列的数据类型必须兼容 4. 返回的结果集不包含重复行,如果需要包含重复行,使用UNION ALL 5. 如果UNION语句中的某个查询需要使用LIMIT或ORDER BY,必须将该查询括在圆括号中 6. 如果子查询没有LIMIT子句, MySQL会忽略ORDER BY子句 7. UNION语句中只能有一个ORDER BY子句,必须放在最后

SELECT first_name FROM actor WHERE actor_id = 88
UNION
SELECT first_name FROM actor WHERE actor_id = 169;

SELECT first_name FROM actor WHERE actor_id = 88
UNION ALL
SELECT first_name FROM actor WHERE actor_id = 169;

SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998;

SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998 ORDER BY return_date ASC LIMIT 5;

-- 查询电影ID为998的所有租赁记录，以及最近的5条租赁记录 第一个子查询没有LIMIT子句，ORDER BY子句会被忽略
(SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998 ORDER BY return_date ASC)
UNION ALL
(SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998 ORDER BY return_date ASC LIMIT 5);

(SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998 ORDER BY return_date ASC)
UNION ALL
(SELECT title, rental_rate, return_date  FROM film JOIN inventory USING(film_id) JOIN rental USING(inventory_id) WHERE film_id = 998 ORDER BY return_date ASC LIMIT 5) ORDER BY return_date DESC;


(SELECT first_name, last_name FROM actor WHERE actor_id < 5)
UNION
(SELECT first_name, last_name FROM actor WHERE actor_id > 190)
ORDER BY first_name LIMIT 4;

SELECT first_name, last_name FROM actor WHERE actor_id < 5 OR actor_id > 190 ORDER BY first_name LIMIT 4;

-- 左连接 左表中有重要数据，但不确定右表中有没有重要数据
SELECT title, return_date FROM film LEFT JOIN inventory USING(film_id) LEFT JOIN rental USING(inventory_id);

SELECT title, return_date FROM rental LEFT JOIN inventory USING(inventory_id) LEFT JOIN film USING(film_id) ORDER BY return_date DESC;

-- 统计租赁电影同一类别次数最多的前5位客户
SELECT email, name as category_name, COUNT(cat.category_id) as cnt FROM customer cs LEFT JOIN rental USING(customer_id)
JOIN inventory USING(inventory_id)
JOIN film_category USING(film_id)
JOIN category cat USING(category_id)
GROUP BY email, category_name
ORDER BY cnt DESC LIMIT 5;

SELECT COUNT(*) FROM category;

-- MySQL会优化掉查询中的所有左连接
SELECT email, name as category_name, COUNT(cat.category_id) as cnt FROM category cat LEFT JOIN film_category fc USING(category_id)
LEFT JOIN inventory USING(film_id)
LEFT JOIN rental i USING(inventory_id)
LEFT JOIN customer cs USING(customer_id)
WHERE cs.email = 'WESLEY.BULL@sakilacustomer.org'
GROUP BY email, category_name
ORDER BY cnt DESC;

INSERT INTO category(name) VALUES ('Thriller');

SELECT cat.name, COUNT(rental_id) as cnt FROM category cat
LEFT JOIN film_category fc USING(category_id)
LEFT JOIN inventory i USING(film_id)
LEFT JOIN rental r USING(inventory_id)
LEFT JOIN customer cs USING(customer_id)
GROUP BY 1
ORDER BY 2 DESC;

SELECT cat.name, COUNT(rental_id) as cnt FROM category cat
JOIN film_category fc USING(category_id)
LEFT JOIN inventory i USING(film_id)
LEFT JOIN rental r USING(inventory_id)
LEFT JOIN customer cs USING(customer_id)
GROUP BY 1
ORDER BY 2 DESC;

SELECT title, return_date  FROM rental
RIGHT JOIN inventory USING(inventory_id)
RIGHT JOIN film USING(film_id)
ORDER BY return_date DESC;

SELECT title, return_date FROM rental
LEFT JOIN inventory USING(inventory_id)
LEFT JOIN film USING(film_id)
ORDER BY return_date DESC;


SELECT COUNT(*) FROM rental
RIGHT JOIN inventory USING(inventory_id)
RIGHT JOIN film USING(film_id);

-- ON和USING子句的区别 ON子句可以使用任何列或表达式,而USING子句只能使用两个表中都存在的列
-- ON子句可以使用表别名,而USING子句不能使用表别名
-- 不使用ON或USING子句时,默认使用CROSS JOIN(笛卡尔积)
-- OUTER LEFT JOIN 和 LEFT JOIN 等价, OUTER RIGHT JOIN 和 RIGHT JOIN 等价, OUTER JOIN 等价于 FULL OUTER JOIN
-- MySQL不支持 FULL OUTER JOIN,可以使用UNION ALL模拟


-- 自然连接 NATURAL JOIN 自动使用两个表中所有同名列进行连接

SELECT first_name, last_name, film_id FROM actor_info NATURAL JOIN film_actor LIMIT 20;

SELECT first_name, last_name, film_id FROM actor_info JOIN film_actor USING(actor_id) LIMIT 20;

SELECT first_name, last_name, film_id FROM actor_info JOIN film_actor WHERE actor_info.actor_id = film_actor.actor_id LIMIT 20;

SELECT first_name, last_name, film_id FROM actor NATURAL LEFT JOIN film_actor;

EXPLAIN SELECT first_name, last_name, film_id FROM actor NATURAL LEFT JOIN film_actor;

SELECT first_name, last_name, title FROM actor
JOIN film_actor USING(actor_id)
JOIN film USING(film_id)
WHERE actor_id = 11;

SELECT first_name, last_name, title FROM actor
JOIN film_actor
ON actor.actor_id = film_actor.actor_id
AND actor.actor_id = 11
JOIN film USING(film_id);

SELECT email, name as category_name, COUNT(cat.category_id) as cnt FROM category cat LEFT JOIN film_category fc USING(category_id)
LEFT JOIN inventory USING(film_id)
LEFT JOIN rental i USING(inventory_id)
LEFT JOIN customer cs ON cs.customer_id = i.customer_id
AND cs.email = 'WESLEY.BULL@sakilacustomer.org'
GROUP BY email, category_name
ORDER BY cnt DESC;


-- 嵌套查询
