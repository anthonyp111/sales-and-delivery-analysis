-- Supply Chain Analysis Project --

-- Preview Data
SELECT COUNT(*)
FROM supply_chain_project.trimmed_supply_chain;

SELECT *
FROM supply_chain_project.trimmed_supply_chain
LIMIT 100;

-- Data cleaning (incorrect state values)
SET SQL_SAFE_UPDATES = 0;

UPDATE supply_chain_project.trimmed_supply_chain
SET customer_state = 'CA'
WHERE customer_state IN ('91732', '95758');

SET SQL_SAFE_UPDATES = 1;

-- Add cleaned date column
ALTER TABLE supply_chain_project.trimmed_supply_chain
ADD COLUMN order_date_clean DATE;

SET SQL_SAFE_UPDATES = 0;

UPDATE supply_chain_project.trimmed_supply_chain
SET order_date_clean = STR_TO_DATE(order_date, '%c/%e/%Y');

SET SQL_SAFE_UPDATES = 1;

-- Verify date conversion
SELECT order_date, order_date_clean
FROM supply_chain_project.trimmed_supply_chain
LIMIT 10;

-- #1 What states generate the most sales?     
SELECT 
	customer_state,
    ROUND(SUM(order_item_total),2) as total_sales
FROM supply_chain_project.trimmed_supply_chain
GROUP BY customer_state
ORDER BY total_sales DESC;
-- Note : This data includes sales within the US including Puerto Rico.
-- Insight: Puerto Rico generates the highest sales, indicating strong revenue concentration in a key area, with a significant gap from the next highest state (CA).

-- #2 Which product category generates the most revenue?
SELECT category_name, ROUND(SUM(order_item_total),2) as total_sales
FROM supply_chain_project.trimmed_supply_chain
GROUP BY category_name
ORDER BY total_sales DESC;
-- Insight: The Fishing category generates the most revenue, making it a key driver of overall sales performance.

-- #3 What product categories are the most profitable?
SELECT category_name,
       ROUND(SUM(order_profit_per_order), 2) AS total_profit,
       ROUND(SUM(order_profit_per_order) * 100.0 / SUM(order_item_total), 2) AS profit_margin
FROM supply_chain_project.trimmed_supply_chain
GROUP BY category_name
ORDER BY total_profit DESC;
-- Insight: The Fishing category generates the highest total profit, overall follows the same pattern as the revenue list found in the previous query.

-- #4 What percentage of orders are delivered late?
SELECT 
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN days_for_shipping_real > days_for_shipment_scheduled 
            THEN order_id 
        END) * 100.0
        / COUNT(DISTINCT order_id), 
    2) AS late_percentage
FROM supply_chain_project.trimmed_supply_chain;
-- Insight: Approximately 57.33% of orders are delivered late, which displays potential inefficiencies in the shipping process.

-- #5 Which shipping method experiences the most late deliveries?
SELECT shipping_method,
       COUNT(DISTINCT order_id) AS total_orders,
       COUNT(DISTINCT CASE WHEN Late_delivery_risk = 1 THEN order_id END) AS late_orders,
       ROUND(COUNT(DISTINCT CASE WHEN Late_delivery_risk = 1 THEN order_id END) * 100.0 / 
       COUNT(DISTINCT order_id), 2) AS late_percentage
FROM supply_chain_project.trimmed_supply_chain
GROUP BY shipping_method
ORDER BY late_percentage DESC;
-- Insight: First Class shipping has the highest percentage of late deliveries, raising concerns as customers pay for faster delivery.

-- #6 Are scheduled timelines accurate?
SELECT 
    delivery_status,
    COUNT(DISTINCT order_id) AS total_orders,
    ROUND(
        COUNT(DISTINCT order_id) * 100 / total.total_orders, 
        2
    ) AS percentage_of_total
FROM (
    SELECT 
        order_id,
        CASE 
            WHEN days_for_shipping_real > days_for_shipment_scheduled THEN 'Late'
            WHEN days_for_shipping_real = days_for_shipment_scheduled THEN 'On Time'
            ELSE 'Early'
        END AS delivery_status
    FROM supply_chain_project.trimmed_supply_chain
) t
JOIN (
    SELECT COUNT(DISTINCT order_id) AS total_orders
    FROM supply_chain_project.trimmed_supply_chain
) total
GROUP BY delivery_status, total.total_orders;
-- Insight: Over 50% of orders arrive late compared to scheduled timelines, suggesting shipping estimates may be overly optimistic.

-- #7 What are the monthly sales trends?
SELECT 
    YEAR(order_date_clean) AS year,
    MONTH(order_date_clean) AS month,
    ROUND(SUM(order_item_total), 2) AS revenue
FROM supply_chain_project.trimmed_supply_chain
WHERE YEAR(order_date_clean) IN (2015, 2016, 2017)
GROUP BY year, month
ORDER BY year, month;
-- Insight: Monthly revenue trends provide a foundation for identifying demand patterns which is shown in Tableau dashboard.
