CREATE OR REPLACE VIEW orders      AS SELECT * FROM 'data/olist/olist_orders_dataset.csv';
CREATE OR REPLACE VIEW order_items AS SELECT * FROM 'data/olist/olist_order_items_dataset.csv';
CREATE OR REPLACE VIEW payments    AS SELECT * FROM 'data/olist/olist_order_payments_dataset.csv';
CREATE OR REPLACE VIEW reviews     AS SELECT * FROM 'data/olist/olist_order_reviews_dataset.csv';
CREATE OR REPLACE VIEW customers   AS SELECT * FROM 'data/olist/olist_customers_dataset.csv';
CREATE OR REPLACE VIEW sellers     AS SELECT * FROM 'data/olist/olist_sellers_dataset.csv';
CREATE OR REPLACE VIEW products    AS SELECT * FROM 'data/olist/olist_products_dataset.csv';
CREATE OR REPLACE VIEW categories  AS SELECT * FROM 'data/olist/product_category_name_translation.csv';


-- ---------------------------------------------------------
-- Q1: Is the business growing? How many orders were placed each month?
-- (Partial months excluded: data starts late 2016 and ends ~Sep 2018.)
-- ---------------------------------------------------------
SELECT EXTRACT(YEAR  FROM order_purchase_timestamp) AS o_year,
       EXTRACT(MONTH FROM order_purchase_timestamp) AS o_month,
       COUNT(*) AS n_orders
FROM orders
WHERE order_purchase_timestamp >= '2017-01-01'
  AND order_purchase_timestamp <  '2018-09-01'
GROUP BY 1, 2
ORDER BY 1, 2;
-- Answer: Orders grew from ~800 (Jan 2017) to ~7,500 (late 2017), then plateaued
-- around ~6,500/month through Aug 2018. The Nov 2017 spike is Black Friday.
-- -> Fast growth in 2017 has stalled in 2018; worth investigating why
--    (saturation, competition, or a change in data collection).


-- ---------------------------------------------------------
-- Q2: Which 10 product categories bring in the most revenue?
-- Metric: GMV = sum of item prices, delivered orders only,
-- excluding freight and uncategorized products. Currency: BRL.
-- ---------------------------------------------------------
SELECT c.product_category_name_english,
       ROUND(SUM(oi.price), 2) AS gmv
FROM order_items AS oi
  INNER JOIN orders AS o
    ON o.order_id = oi.order_id
  INNER JOIN products AS p
    ON oi.product_id = p.product_id
  INNER JOIN categories AS c
    ON p.product_category_name = c.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY c.product_category_name_english
ORDER BY gmv DESC
LIMIT 10;
-- Answer: health_beauty is the top category: 1,233,131.72 BRL.
-- Excluding undelivered orders changed the list (toys replaced garden_tools at #10),
-- so the metric definition matters.
-- -> Protect this category; assess its margins and growth before shifting investment.


-- ---------------------------------------------------------
-- Q3: Do late deliveries get worse review scores?
-- Late = delivered after the estimated delivery date. Delivered orders only.
-- ---------------------------------------------------------
SELECT
    CASE
        WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 'late'
        ELSE 'on_time'
    END                           AS delivery,
    ROUND(AVG(r.review_score), 2) AS avg_score,
    COUNT(*)                      AS n_reviews
FROM orders AS o
  INNER JOIN reviews AS r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY 1
ORDER BY avg_score;
-- Answer: late 2.57 vs on-time 4.29 (a 1.7-point gap); ~8% of reviews are on late orders.
-- -> Delays are strongly associated with poor reviews (association, not proven cause).
--    Reducing lateness, or setting more realistic delivery estimates, is a likely lever.


-- ---------------------------------------------------------
-- Q4: Which sellers have sold more than 100 items, and what's their average item price?
-- (All orders included, canceled ones too.)
-- ---------------------------------------------------------
SELECT seller_id,
       COUNT(*)              AS n_items,
       ROUND(AVG(price), 2)  AS avg_price
FROM order_items
GROUP BY seller_id
HAVING COUNT(*) > 100
ORDER BY n_items DESC;
-- Answer: 236 sellers (~8% of ~3,100) sold more than 100 items. The top seller by volume
-- (2,033 items at ~61 BRL) brings in less value (~123k BRL) than #11 (1,156 items at
-- ~199 BRL, ~229k BRL).
-- -> A small group of high-volume sellers matters a lot to the platform, but who counts
--    as "most important" depends on ranking by items (volume) or by price (value).


-- ---------------------------------------------------------
-- Q5: How much bigger was Black Friday 2017 than an average day in November 2017?
-- Baseline excludes Black Friday itself.
-- ---------------------------------------------------------
WITH n_orders_by_date_november AS (
    SELECT CAST(order_purchase_timestamp AS DATE) AS purchase_date,
           COUNT(*) AS n_orders
    FROM orders
    WHERE order_purchase_timestamp >= '2017-11-01'
      AND order_purchase_timestamp <  '2017-12-01'
    GROUP BY 1
)
SELECT
    CASE
        WHEN purchase_date = '2017-11-24' THEN 'BLACK FRIDAY'
        ELSE 'OTHER DAYS IN NOVEMBER'
    END                         AS november_day,
    ROUND(AVG(n_orders), 2)     AS avg_orders,
    ROUND(MEDIAN(n_orders), 2)  AS median_orders
FROM n_orders_by_date_november
GROUP BY 1;
-- Answer: Black Friday 2017: 1,176 orders. Other November days: mean 219.59,
-- median 192 (mean > median -> skewed by the days around Black Friday).
-- -> Black Friday ~6.1x a typical day (median baseline); capacity planning
--    (sellers, logistics, support) must handle 6x peaks.