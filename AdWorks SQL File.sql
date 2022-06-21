/* I'll be looking at data for AdventureWorks, a compnay that sells outdoor sporting equipment.  In this project, I'll be looking at what are their best products and salespeople and how can the company use this information to improve overall performanc */

/* What are AdventureWork's most popular products?" */
	  
	 SELECT DISTINCT 
			product.productid,
			product.name,
			AVG(productreview.rating) AS avgrating,
			RANK() OVER(ORDER BY productreview.rating DESC) AS num_ratings
	FROM product
	INNER JOIN productreview ON product.productid = productreview.productid
	GROUP BY 2
	ORDER BY productreview.rating DESC
	LIMIT 10;
	
SELECT *
FROM  productreview;

/*  Why did only 3 product come out of the query? After taking a closer look at the productreview table, I realize that only 4 products have reviews, so I'll
	need to find an alternative way to look at the most popular products */
	
	SELECT productmodelid, description
	FROM productmodelproductdescriptionculture pm
	JOIN productdescription pd
	ON pm.productdescriptionid = pd.productdescriptionid
	WHERE cultureid = "en";
	

/* I'm going to look at the total number of sales for the top selling products. Because there are products sold to multiple countries, I'm only going to look at products from  predominantly english speaking countries */

	SELECT 	productmodelid, description FROM	
	(
		SELECT cultureid, productmodelid, description FROM
		(
			SELECT 
			pm.cultureid,
			pm.productdescriptionid,
			pm.productmodelid,
			pd.description
			FROM productmodelproductdescriptionculture pm
			JOIN productdescription pd
			ON pm.productdescriptionid = pd.productdescriptionid
		 ) a
	WHERE cultureid = "en"
    )	b;

-- using previous query as a temporary view for looking at the top selling products with English descriptions--

WITH md AS
(
	SELECT 	productmodelid, description FROM	
	(
		SELECT cultureid, productmodelid, description FROM
		(
			SELECT 
			pm.cultureid,
			pm.productdescriptionid,
			pm.productmodelid,
			pd.description
			FROM productmodelproductdescriptionculture pm
			JOIN productdescription pd
			ON pm.productdescriptionid = pd.productdescriptionid
		 ) a
	WHERE cultureid = "en"
    )	b
)
SELECT 
	p.productmodelid,
	p.NAME,
	md.description,
	SUM(s.orderqty) AS total_orders
FROM product p
	INNER JOIN md
		ON p.productmodelid = md.productmodelid
	INNER JOIN salesorderdetail s
		ON p.productid = s.productid
GROUP BY p.NAME
ORDER BY total_orders DESC
LIMIT 10; 
		

-- looking at the correlation between quantity sold and price for each subcategory
	
SELECT DISTINCT 
	productid,
	SUM(salesorderdetail.orderqty) AS quantity
FROM salesorderdetail
GROUP BY 1 
ORDER BY 1;

-- getting list price for each category --

SELECT 
	p.productid,
	pc.name AS category,
	ps.name AS subcategoty,
	p.listprice
FROM productsubcategory ps
	INNER JOIN productcategory pc
		ON ps.productcategoryid = pc.productcategoryid
	INNER JOIN product p
		ON ps.productsubcategoryid = p.productsubcategoryid
GROUP BY productid
ORDER BY productid;

--merging the two previous tables --

WITH item_quantity AS 
(
    SELECT DISTINCT
        productid, 
        SUM(salesorderdetail.orderqty) AS quantity
    FROM salesorderdetail 
    GROUP BY productid
    ORDER BY productid
),
category_price AS
(
    SELECT 
        p.productid, 
        pc.name AS category,
        ps.name AS subcategory,
        p.listprice
    FROM productsubcategory ps
        INNER JOIN productcategory pc
			ON ps.productcategoryid = pc.productcategoryid
        INNER JOIN product p
			ON ps.productsubcategoryid = p.productsubcategoryid
    GROUP BY productid
    ORDER BY productid
)
SELECT 
    cp.category,
    cp.subcategory,
    AVG(cp.listprice) AS average_price_in_subcategory,
    SUM(iq.quantity) AS total_items_sold_in_subcategory
FROM item_quantity iq
JOIN category_price cp
ON iq.productid = cp.productid
GROUP BY cp.subcategory
ORDER BY cp.category
LIMIT 5;

-- FINDING TOP SALESPEOPLE --

SELECT businessentityid, salesytd
FROM salesperson
ORDER BY salesytd DESC
LIMIT 5;

	-- top 5 salespeople from most recent year --
	
SELECT 
    salesorderid,
    SUM((unitprice*orderqty) - (unitprice*orderqty*unitpricediscount)) AS ordertotal
FROM salesorderdetail
GROUP BY salesorderid
LIMIT 5;
	
WITH previous AS (
        SELECT 
            salesorderid,
            SUM((unitprice*orderqty) - (unitprice*orderqty*unitpricediscount)) AS ordertotal
        FROM salesorderdetail
        GROUP BY salesorderid
    )

    SELECT 
        so.salespersonid, 
        SUM(previous.ordertotal) AS ordertotalsum 
    FROM salesorderheader so
        INNER JOIN previous 
		ON so.salesorderid = previous.salesorderid
    WHERE orderdate >= '2014-01-01'
    AND salespersonid <> ""
    GROUP BY salespersonid
    ORDER BY ordertotalsum DESC
    LIMIT 5;
	
	-- joining previous query in this one to see relationship between total sales and commission percentages --
	
WITH previous AS (
        SELECT 
            salesorderid,
            SUM((unitprice*orderqty) - (unitprice*orderqty*unitpricediscount)) AS ordertotal
        FROM salesorderdetail
        GROUP BY salesorderid
    ),

	query2 AS (
    SELECT 
        so.salespersonid, 
        SUM(previous.ordertotal) AS ordertotalsum 
    FROM salesorderheader so
        INNER JOIN previous 
		ON so.salesorderid = previous.salesorderid
    WHERE orderdate >= '2014-01-01'
    AND salespersonid <> ""
    GROUP BY salespersonid
    ORDER BY ordertotalsum DESC
)	
	SELECT 
        query2.salespersonid, 
		query2.ordertotalsum, 
		sp.commissionpct
    FROM query2 
    INNER JOIN salesperson sp
		ON sp.businessentityid = query2.salespersonid
    GROUP BY salespersonid
	ORDER BY ordertotalsum DESC;
	
	/* looks like more sales shows a higher commission, but we have to take into consideration that some
	of these salespeople are in different countries and so we need to look at their sales and commissionpct
	by currency code */
	
SELECT 
    sp.businessentityid,
    crc.currencycode
FROM salesterritory st
    JOIN salesperson sp
		ON st.territoryid = sp.territoryid
    JOIN countryregioncurrency crc
		ON st.countryregioncode = crc.countryregioncode
ORDER BY sp.businessentityid;


 WITH previous AS (
        SELECT 
            salesorderid,
            SUM((unitprice*orderqty) - (unitprice*orderqty*unitpricediscount)) AS ordertotal
        FROM salesorderdetail
        GROUP BY salesorderid
    ),

	query2 AS (
    SELECT 
        so.salespersonid, 
        SUM(previous.ordertotal) AS ordertotalsum 
    FROM salesorderheader so
        INNER JOIN previous 
		ON so.salesorderid = previous.salesorderid
    WHERE orderdate >= '2014-01-01'
    AND salespersonid <> ""
    GROUP BY salespersonid
    ORDER BY ordertotalsum DESC
),
	query3 AS (
	SELECT 
    sp.businessentityid,
    crc.currencycode
	FROM salesterritory st
		JOIN salesperson sp
			ON st.territoryid = sp.territoryid
		JOIN countryregioncurrency crc
			ON st.countryregioncode = crc.countryregioncode
	ORDER BY sp.businessentityid
	)
	  SELECT 
       query2.salespersonid, 
	   query2.ordertotalsum, 
	   sp.commissionpct,
	   query3.currencycode
    FROM query2
        INNER JOIN query3
			ON query3.businessentityid = query2.salespersonid
        INNER JOIN salesperson sp
			ON sp.businessentityid = query3.businessentityid
    ORDER BY currencycode ASC, ordertotalsum DESC
	LIMIT 5;