-- inspecting the  data
select * from [project].[dbo].[sales_data_sample]

-- identifying the unique value
select distinct status from [project].[dbo].[sales_data_sample]
select distinct Year_id from [project].[dbo].[sales_data_sample]
select distinct PRODUCTLINE from [project].[dbo].[sales_data_sample]
select distinct COUNTRY from [project].[dbo].[sales_data_sample]
select distinct DEALSIZE from [project].[dbo].[sales_data_sample]
select distinct TERRITORY from [project].[dbo].[sales_data_sample]


select distinct MONTH_ID from [project].[dbo].[sales_data_sample]
where YEAR_ID =2005


--- Analysis
-- first be groupby the sales from the product line
 select productline,SUM(sales)revenue from [project].[dbo].[sales_data_sample]
 group by PRODUCTLINE
 order by 2 desc;


-- first be groupby the sales from the year_id
 select YEAR_ID,SUM(sales)revenue from [project].[dbo].[sales_data_sample]
 group by YEAR_ID
 order by 2 desc;

 -- first be groupby the sales from the deal size
 select DEALSIZE,SUM(sales)revenue from [project].[dbo].[sales_data_sample]
 group by DEALSIZE
 order by 2 desc;


 -- now we can see what is the best month for the sales and how much they earned from that year
 select MONTH_ID,SUM(sales)revenue,COUNT(Ordernumber)frequency
 from [project].[dbo].[sales_data_sample]
 where YEAR_ID=2003
 group by MONTH_ID
 order by 2 desc;

 --November seems to be the month,What product do they sell in november,classic I Believe
 select MONTH_ID,PRODUCTLINE,SUM(sales)revenue,COUNT(Ordernumber)Orders 
 from [project].[dbo].[sales_data_sample]
 where YEAR_ID=2003 and MONTH_ID=11
 group by MONTH_ID,PRODUCTLINE
 order by 3 desc;

 ----Who is our best customer (this could be best answered with RFM)


DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(ORDERDATE) last_order_date,
		(select max(ORDERDATE) from [project].[dbo].[sales_data_sample]) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [project].[dbo].[sales_data_sample])) Recency
	from [project].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as
(

	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by Frequency) rfm_frequency,
		NTILE(4) OVER (order by MonetaryValue) rfm_monetary
	from rfm r
)
select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
into #rfm
from rfm_calc c

select  CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers'
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432,421) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

from #rfm


--What city has the highest number of sales in a specific country
select city, sum (sales) Revenue
from [project].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



---What is the best product in United States?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from [project].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc