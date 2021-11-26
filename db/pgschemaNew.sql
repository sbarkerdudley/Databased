-- DROP DATABASE reviews;

-- CREATE DATABASE reviews;

\c reviews;

-- CREATE SCHEMA IF NOT EXISTS reviews;

-- CREATE TABLE reviews.products (
--   id INT PRIMARY KEY NOT NULL,
--   -- characteristics TEXT, -- fix this
--   quality INT,
--   size INT,
--   width INT,
--   fit INT,
--   length INT,
--   comfort INT
-- );


-- CREATE TEMP TABLE importreviews (
--   review_id INT,
--   product_id INT,
--   rating SMALLINT,
--   date BIGINT,
--   summary TEXT,
--   body TEXT,
--   recommend BOOLEAN DEFAULT TRUE,
--   reported BOOLEAN DEFAULT FALSE,
--   reviewer_name TEXT,
--   reviewer_email TEXT,
--   response TEXT,
--   helpfulness SMALLINT DEFAULT 0
-- );

-- \copy importreviews from './csv/reviews.csv' delimiter ',' csv header;

-- INSERT INTO reviews.products (id)
-- SELECT DISTINCT product_id
-- FROM importreviews
-- ORDER BY product_id ASC;


-- CREATE TABLE reviews.list (
--   review_id INT PRIMARY KEY NOT NULL,
--   -- review_id INT GENERATED BY DEFAULT AS IDENTITY,
--   product_id INT REFERENCES reviews.products(id),
--   rating SMALLINT NOT NULL,
--   date TIMESTAMPTZ,
--   summary VARCHAR(120) NOT NULL,
--   body VARCHAR(480),
--   response VARCHAR(110),
--   recommend BOOLEAN,
--   reviewer_name VARCHAR(30) NOT NULL,
--   reviewer_email VARCHAR(40) NOT NULL,
--   helpfulness SMALLINT,
--   reported BOOLEAN
-- );

-- INSERT INTO reviews.list
-- SELECT review_id, product_id, rating,
-- date_trunc('day', to_timestamp(date / 1000) AT TIME ZONE 'UTC'),
-- summary, body, response, recommend, reviewer_name, reviewer_email, helpfulness, reported
-- FROM importreviews;


-- DROP TABLE importreviews;


-- CREATE TABLE reviews.photos (
--   id INT PRIMARY KEY NOT NULL,
--   url VARCHAR(160),
--   review_id INT REFERENCES reviews.list(review_id)
-- );

-- CREATE TEMP TABLE importphotos (
--   id INT,
--   review_id INT,
--   url TEXT
-- );


-- \copy importphotos from './csv/reviews_photos.csv' delimiter ',' csv header;

-- INSERT INTO reviews.photos (id, review_id, url)
-- SELECT id, review_id, url
-- FROM importphotos;


-- CREATE INDEX rp_idx ON reviews.list (product_id, review_id, date, helpfulness);

-- CREATE INDEX rph_idx ON reviews.photos (review_id, id);


-- CREATE OR REPLACE VIEW reviews.meta AS
-- SELECT product_id,
-- jsonb_object_agg(rating, count) AS ratings,
-- jsonb_object_agg(recommend, count) AS recommended
-- FROM (SELECT product_id, rating, recommend, count(*)
-- FROM reviews.list
-- GROUP BY product_id, rating, recommend) foo
-- GROUP BY product_id
-- ORDER BY product_id;


-- CREATE OR REPLACE VIEW photos_json AS SELECT COALESCE (
--   json_agg(json_build_object( 'id', reviews.photos.id, 'url', url) ) FILTER (WHERE url IS NOT NULL),
--   '[]' ) photos from reviews.photos
--   RIGHT JOIN reviews.list ON
--   (list.review_id=photos.review_id)
--   GROUP BY reviews.list.product_id, reviews.list.review_id;


-- -- //////////////
-- CREATE TYPE spec AS ENUM (
--   'quality','size','width','fit','length','comfort'
-- );

-- CREATE TABLE IF NOT EXISTS reviews.specs (
--   id INT PRIMARY KEY NOT NULL,
--   product_id INT NOT NULL REFERENCES reviews.products(id),
--   name spec
-- );



-- CREATE TEMP TABLE importspecs (
--   id INT,
--   product_id INT,
--   name VARCHAR
-- );

-- \copy importspecs from './csv/characteristics.csv' delimiter ',' csv header;

-- INSERT INTO reviews.specs SELECT s.id, product_id, LOWER(name)::spec FROM importspecs s
-- JOIN reviews.products p ON s.product_id=p.id;

-- CREATE INDEX s_idx ON reviews.specs (product_id, id);




-- CREATE TABLE IF NOT EXISTS reviews.spec_reviews (
--   id BIGINT GENERATED BY DEFAULT AS IDENTITY,
--   characteristic_id INT REFERENCES reviews.specs(id),
--   review_id INT REFERENCES reviews.list(review_id),
--   value SMALLINT
-- );


-- CREATE TEMP TABLE importspecreviews (
--   id BIGINT,
--   characteristic_id INT,
--   review_id INT,
--   value INT
-- );


-- \copy importspecreviews from './csv/characteristic_reviews.csv' delimiter ',' quote '"'csv header;

-- INSERT INTO reviews.spec_reviews
-- SELECT s.id, characteristic_id, review_id, value
-- FROM importspecreviews s;


-- CREATE INDEX s_avg ON reviews.spec_reviews (review_id, characteristic_id, value);

CREATE OR REPLACE VIEW specs_avg AS
SELECT jsonb_object_agg(characteristic_id, value) AS avgs
FROM (SELECT review_id, characteristic_id, value, count(*)
FROM reviews.spec_reviews -- is taking the cout and not the AVG() -- fix this syntax
-- maybe create another view first that aggregates based on characteristic_id ?
GROUP BY review_id, characteristic_id, value) foo
GROUP BY review_id;

-- get product id from specs, join on reviews, select average of reviews compile into an object.
-- create an index on the view or use a materialized view?
-- incorporate into reviews.meta ...

/* FOR REFERENCE

-- CREATE OR REPLACE VIEW reviews.meta AS //
-- SELECT product_id,
-- jsonb_object_agg(rating, count) AS ratings,
-- jsonb_object_agg(recommend, count) AS recommended
-- FROM (SELECT product_id, rating, recommend, count(*)
-- FROM reviews.list
-- GROUP BY product_id, rating, recommend) foo
-- GROUP BY product_id
-- ORDER BY product_id;

*/


/*  Execute this file from the command line by typing:


psql -U ciele postgres -f ./db/pgschemaNew.sql

  *  to create the database, schema, and the tables.
  *  note: opens to database 'postgres' then \c to database 'reviews'

  head -7 answers_photos.csv

*/

/*


 select * from reviews.list left join reviews.photos on (reviews.list.review_id = reviews.photos.review_id)
where (reviews.list.product_id=3456);

*/

/*

from EC2:

sudo -u postgres psql -f ./db/pgschemaNew.sql

*/
