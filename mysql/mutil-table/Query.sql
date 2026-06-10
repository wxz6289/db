show databases;

select * from tb_emp e, tb_dept d where e.dept_id = d.id;
select tb_emp.name, tb_dept.name from tb_emp inner join tb_dept on tb_dept.id = tb_emp.dept_id;

use users;
alter table  tb_user rename users;

select name, age from users where age <= 26;

create database mybatis;

use mybatis;
create table users as select * from users.users;

create table dept(
    id int unsigned primary key auto_increment,
    name varchar(20) not null unique comment "部门名称",
    createdAt datetime not null comment "记录创建时间",
    updatedAt datetime not null comment "记录更新时间"
) comment "部门表";

alter table  dept modify createdAt datetime not null default current_timestamp;
alter table user add updatedAt datetime not null  default current_timestamp on update current_timestamp;

show create table dept;
insert into dept(name) values ("行政部"),( "人事部"),("技术部"), ("市场部"),("销售部"),( "客服部");

alter table users rename mybatis.user;
alter table `user` add deptId int comment "部门ID";
alter table user change created_at createdAt datetime default  current_timestamp;
select * from user;
update user set deptId = 4 where id in (7, 6);
update user set deptId = 6 where id = 8;

update user set age = 16 where id =1;