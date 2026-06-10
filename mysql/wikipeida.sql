CREATE DATABASE wikipedia;
CREATE TABLE `wikipedia`.pages (
  `id` INT NOT NULL AUTO_INCREMENT,
  `url` VARCHAR(255) NOT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`));

  CREATE TABLE links (
    `id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    `from_page_id` INT NULL,
    `to_page_id` INT NULL,
    `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
  );

use scraping;
  select count(*) from pages;
  select count(*) from links;
  select * from pages where id > 100;
