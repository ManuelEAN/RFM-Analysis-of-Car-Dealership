-- Inspecting the data
Select * from [Portfolio8].[dbo].[sales_data_sample]


-- Checking unique values

Select distinct status from [Portfolio8].[dbo].[sales_data_sample] ---Good to plot
select distinct year_id from [Portfolio8].[dbo].[sales_data_sample]
select distinct PRODUCTLINE from [Portfolio8].[dbo].[sales_data_sample] ---Good to plot
select distinct COUNTRY from [Portfolio8].[dbo].[sales_data_sample] ---Good to plot
select distinct DEALSIZE from [Portfolio8].[dbo].[sales_data_sample] ---Good to plot
select distinct TERRITORY from [Portfolio8].[dbo].[sales_data_sample]

-- Group sales by productline

select PRODUCTLINE, sum(sales) as Revenue
from [Portfolio8].[dbo].[sales_data_sample]
group by PRODUCTLINE
order by 2 desc

-- Group sales by yearID

select YEAR_ID, sum(sales) as Revenue
from [Portfolio8].[dbo].[sales_data_sample]
group by YEAR_ID
order by 2 desc

-- -- Group sales by Dealsize

select DEALSIZE , sum(sales) as Revenue
from [Portfolio8].[dbo].[sales_data_sample]
group by DEALSIZE
order by 2 desc


-- Best month for sales in a specific year //  Revenue that month

select  MONTH_ID, sum(sales) as Revenue, count(ORDERNUMBER) as Frequency
from [Portfolio8].[dbo].[sales_data_sample]
where YEAR_ID = 2004    --Year to inspect in the query
group by  MONTH_ID
order by 2 desc


-- November is the months with more revenue, Now, find best seller product November

select  MONTH_ID, PRODUCTLINE, ROUND(sum(sales),2) Revenue, count(ORDERNUMBER) as Frequency
from [Portfolio8].[dbo].[sales_data_sample]
where YEAR_ID = 2004 and MONTH_ID = 11  --change year to see the rest
group by  MONTH_ID, PRODUCTLINE
order by 3 desc

--- RFM analysis to find the best custumers

DROP TABLE IF EXISTS #rfm
;with rfm as 
(
	select 
		CUSTOMERNAME, 
		round(sum(sales),2) AS MonetaryValue,
		round(avg(sales),2) AS AvgMonetaryValue,
		count(ORDERNUMBER) AS Frequency,
		max(ORDERDATE) AS LastOrderDate,
		(select max(ORDERDATE) from [Portfolio8].[dbo].[sales_data_sample]) AS MaxOrderDate,
		DATEDIFF(DD, max(ORDERDATE), (select max(ORDERDATE) from [dbo].[sales_data_sample])) AS Recency
	from [Portfolio8].[dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfmCalc as 
(
	select * ,
	ntile(4) over (order by Recency) as rfmRecency,
	ntile(4) over (order by Frequency) as rfmFrequency,
	--ntile(4) over (order by MonetaryValue) as rfmMonerary,
	ntile(4) over (order by AvgMonetaryValue) as rfmAvgMonetary
from rfm
)
select *, 
	rfmRecency+rfmFrequency+rfmAvgMonetary as rfmCell,
	cast(rfmRecency as varchar) + cast(rfmFrequency as varchar) + cast(rfmAvgMonetary as varchar) as rfmCellString
into #rfm
from rfmCalc


select CUSTOMERNAME, rfmRecency, rfmFrequency, rfmAvgMonetary,
  case
    when rfmCell BETWEEN 3 AND 5 then 'Poor customer'
    when rfmCell BETWEEN 5 AND 7 then 'Average customer'
    when rfmCell BETWEEN 7 AND 10 then 'Good customer'
    when rfmCell BETWEEN 10 AND 12 then 'Loyal customer'
  end as rfmCustomerCategory
from #rfm


-- Products sell together

select distinct ORDERNUMBER, stuff(
		(select ',' + PRODUCTCODE
		from [Portfolio8].[dbo].[sales_data_sample] p
		where ORDERNUMBER in 
			(
			select ORDERNUMBER
			from
				(
				select ORDERNUMBER, count(*) as rn
				FROM [Portfolio8].[dbo].[sales_data_sample]
				where STATUS = 'Shipped'
				group by ORDERNUMBER
			)m
			where rn = 2
		) and p.ORDERNUMBER = s.ORDERNUMBER
		for xml path ('')
),1,1,'') as ProductCodes
from [Portfolio8].[dbo].[sales_data_sample] s
order by 2 desc




-- City with highest sales in a specific country

select city, round(sum (sales),2) as Revenue
from [Portfolio8].[dbo].[sales_data_sample]
where country = 'UK'
group by city
order by 2 desc



--- Product with more sells in United States?

select country, YEAR_ID, PRODUCTLINE, round(sum(sales),2) as Revenue
from [Portfolio8].[dbo].[sales_data_sample]
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc