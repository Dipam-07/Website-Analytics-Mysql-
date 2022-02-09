/* CONVERTION RATE BY EACH UTM SOURCE*/
select website_sessions.utm_source As UTM_SOURCE,count(distinct website_sessions.website_session_id) TOTAL_Sessions,
count(distinct orders.order_id) as Total_order,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id)*100 as CVR_Rate_Percentage 
from website_sessions
left join orders on orders.website_session_id=website_sessions.website_session_id
group by 1 ;

/* FOR 2012 MONTH WISE BID OPTIMIZATION EACH DEVICE LEVEL TRENDS */
select Monthly_Increase_Values,Desktop_session,Mobile_session from(select year(created_at),monthname(created_at)Monthly_Increase_Values,Min(date(created_at)) Week_to_Start,
count(distinct case when device_type='desktop' then website_session_id else null end) AS Desktop_session,
count(distinct case when device_type='mobile' then website_session_id else null end) AS Mobile_session
from website_sessions
where created_at between  '2012-01-01' and '2012-12-31' and utm_source='gsearch' and utm_campaign ='nonbrand'
group by Month(created_at))B;


/*Convertion Funnel Analysis From June 2012 To August 2012*/
create temporary table funnel_analysis22
select website_sessions.website_session_id,
website_pageviews.pageview_url,website_pageviews.created_at as pageview_created_at,
case when pageview_url = '/products' then 1 else 0 end as product_page,
case when pageview_url = '/the-original-mr-fuzzy' then 1 else 0 end as mrfuzzy_page,
case when pageview_url = '/cart' then 1 else 0 end as cart_page,
case when pageview_url = '/shipping' then 1 else 0 end as shipping_page,
case when pageview_url = '/billing' then 1 else 0 end as billing_page,
case when pageview_url = '/thank-you-for-your-order' then 1 else 0 end as thanku_page
from website_sessions
left join website_pageviews on website_sessions.website_session_id=website_pageviews.website_session_id
where website_sessions.utm_source='gsearch' and website_sessions.utm_campaign='nonbrand' and website_sessions.created_at between '2012-06-06' and '2012-09-05'
order by 1;

create temporary table funnel_analysis_part24
select funnel_analysis22.website_session_id,max(funnel_analysis22.product_page) as Product_count,
max(funnel_analysis22.mrfuzzy_page) mrfuzzy_page_count,max(funnel_analysis22.cart_page) cart_page_count,max(funnel_analysis22.shipping_page) shiiping_page_count,
max(funnel_analysis22.billing_page) billing_page_count,max(funnel_analysis22.thanku_page) thanku_page_count
from funnel_analysis22
left join website_sessions on website_sessions.website_session_id=funnel_analysis22.website_session_id
group by 1;
select * from funnel_analysis_part24;

select count(distinct funnel_analysis_part24.website_session_id) as total_Visitor,
count(case when product_count=1 then website_session_id else null end) as to_product,
count(case when mrfuzzy_page_count=1 then website_session_id else null end) as to_Toys,
count(case when cart_page_count=1 then website_session_id else null end) as to_Add_to_Cart,
count(case when shiiping_page_count=1 then website_session_id else null end) as to_Shipping,
count(case when billing_page_count=1 then website_session_id else null end) as to_Billing,
count(case when thanku_page_count=1 then website_session_id else null end) as to_Placed_Order_Thanku
from funnel_analysis_part24;

select count(distinct funnel_analysis_part24.website_session_id) as Total_Visitor,
count(case when product_count=1 then website_session_id else null end)/count(distinct funnel_analysis_part24.website_session_id)*100  as Clicked_to_product,
count(case when mrfuzzy_page_count=1 then website_session_id else null end)/count(case when product_count=1 then website_session_id else null end)*100 as Clicked_to_Toys,
count(case when cart_page_count=1 then website_session_id else null end)/count(case when mrfuzzy_page_count=1 then website_session_id else null end)*100 as Clicked_to_Add_to_Cart,
count(case when shiiping_page_count=1 then website_session_id else null end)/count(case when cart_page_count=1 then website_session_id else null end)*100 as Clicked_to_Shipping,
count(case when billing_page_count=1 then website_session_id else null end)/count(case when shiiping_page_count=1 then website_session_id else null end)*100 as Clicked_to_Billing,
count(case when thanku_page_count=1 then website_session_id else null end)/count(case when billing_page_count=1 then website_session_id else null end)*100 as Clicked_to_Placed_Order_Thanku
from funnel_analysis_part24;
/*Identifying Top website Landing Pages*/
select pageview_url,count(distinct website_pageview_id) as Total_Page_View From website_pageviews group by 1 order by Total_Page_View desc;

/*User Behaviour Analysis*/
create temporary table Repeat_Session_Count
select
new_sessions.user_id,
new_sessions.website_session_id as new_session_id,
website_sessions.website_session_id as Repeat_session_id from
(select user_id,website_session_id from website_sessions 
where created_at <'2014-11-01' and created_at >'2014-01-01' and is_repeat_session=0) as new_sessions
left join website_sessions
on website_sessions.user_id=new_sessions.user_id
and website_sessions.is_repeat_session =1
and website_sessions.website_session_id > new_sessions.website_session_id
and website_sessions.created_at  <'2014-11-01' and  created_at >'2014-01-01' ;
select * from Repeat_Session_Count;
select Repeat_sessions,count(distinct user_id) AS Users From
(select user_id,count(distinct new_session_id) As New_session,count(distinct repeat_session_id) as repeat_sessions from repeat_session_count
group by 1 order by 3 desc) as user_level group by 1;

/*Product Level Sales Analysis*/
create temporary table sales_update1234
select primary_product_id, monthname(created_at) As Monthly_Report,year(created_at) As Yearly_Report,
count(order_id) As No_of_sales,
sum(price_usd) as Revenue,
sum(price_usd-cogs_usd) as Margin
from orders
group by 1,2 
order by 2 desc;
select product_name,Yearly_Report,Monthly_Report,No_of_sales,Revenue,Margin from sales_update1234
left join products on sales_update1234.primary_product_id=products.product_id
group by 1,2,3
order by 3 desc ,4 desc,5 desc;

/*Product Level Launch Analysis- Improvement of Convertion Rate And Revenue PerSession from this analysis*/
select 
year(website_sessions.created_at) As Year_Wise_Report,
monthname(website_sessions.created_at) As Month_Wise_Report,
count(distinct website_sessions.website_session_id) as Sessions,
count(distinct orders.order_id) as Orders,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as Overall_Convertion_Rate,
sum(orders.price_usd)/count(distinct website_sessions.website_session_id) As Revenue_Per_session,
count(case when primary_product_id=1 then order_id else null end) As Product_one_order,
count(case when primary_product_id=2 then order_id else null end) As Product_two_order
from website_sessions
left join orders on website_sessions.website_session_id=orders.order_id
where website_sessions.created_at between '2012-01-01' and '2012-12-31'
group by 1,2;

/*Product Refund Rates Analysis*/
select year(order_items.created_at) As Year_Wise,
monthname(order_items.created_at) As Month_Wise,
products.product_name,
count(distinct case when order_items. product_id =1 then order_items.order_item_id else null end) as P1_Orders,
count(distinct case when order_items. product_id =1 then order_item_refunds.order_item_id else null end)/count(distinct case when order_items. product_id =1 then order_items.order_item_id else null end)*100 as P1_refund_rate,
count(distinct case when order_items. product_id =2 then order_items.order_item_id else null end) as p2_orders,
count(distinct case when order_items. product_id =2 then order_item_refunds.order_item_id else null end)/count(distinct case when order_items. product_id =2 then order_items.order_item_id else null end)*100 as P2_Refund_Rate,
count(distinct case when order_items. product_id =3 then order_items.order_item_id else null end) as P3_orders,
count(distinct case when order_items. product_id =3 then order_item_refunds.order_item_id else null end)/count(distinct case when order_items. product_id =3 then order_items.order_item_id else null end)*100 as P3_Refund_Rate,
count(distinct case when order_items. product_id =4 then order_items.order_item_id else null end) as P4_Orders,
count(distinct case when order_items. product_id =4 then order_item_refunds.order_item_id else null end)/count(distinct case when order_items. product_id =4 then order_items.order_item_id else null end)*100 as P4_Refund_Rate
from order_items
left join order_item_refunds
on order_items.order_item_id=order_item_refunds.order_item_id
left join products
on  order_items.product_id=products.product_id
group by 1,2;
/*Business seasonility analysis*/
select
year(website_sessions.created_at) As Years,
quarter(website_sessions.created_at) As Quarters,
count(distinct website_sessions.website_session_id) As Total_S_Made,
count(distinct orders.order_id)As Total_Orders,
sum(orders.price_usd) As Revenue,
sum(orders.price_usd-orders.cogs_usd) As Profit_OR_Loss_Margin
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id
group by 1,2;


/*Google Search is the top utm_source so here is the analysis of monthly trends and orders made from gsearch to find growth rate*/
select
year(website_sessions.created_at) as Year_Wise,
monthname(website_sessions.created_at) As Month_Wise,
count(website_sessions.website_session_id) as Total_Sessions,
count(orders.order_id) as Total_Orders
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id
WHERE website_sessions.utm_source='GSEARCH'
group by 1,2;
/*Device type convertion rate to analyze traffic sources*/
select 
year(website_sessions.created_at) As Year_Wise,
monthname(website_sessions.created_at) As Month_Wise,
count(case when website_sessions.device_type='desktop' then website_sessions.website_session_id else null end) as desktop_session,
count(case when website_sessions.device_type='desktop' then orders.order_id else null end) as Desktop_orders,
count(case when website_sessions.device_type='desktop' then website_sessions.website_session_id else null end)
/count(case when website_sessions.device_type='desktop' then orders.order_id else null end) as Convertion_Rate_By_Desktop,
count(case when website_sessions.device_type='Mobile' then website_sessions.website_session_id else null end) as Mobile_session,
count(case when website_sessions.device_type='Mobile' then orders.order_id else null end) as Mobile_Orders,
count(case when website_sessions.device_type='Mobile' then website_sessions.website_session_id else null end)
/count(case when website_sessions.device_type='Mobile' then orders.order_id else null end) As Convertion_Rate_By_Mobile
from website_sessions
left join orders on website_sessions.website_session_id=orders.order_id
where website_sessions.created_at between '2012-01-01' and '2012-12-31'
group by 1,2;
/*Overall improvement growth analysis including sessions to order,revenue per session,revenue per order for the year 2012*/
select
year(website_sessions.created_at) as Year_wise,
quarter(website_sessions.created_at) As Quaters,
count(distinct orders.order_id)/count(distinct website_sessions.website_session_id) as Convertion_Rate,
sum(orders.price_usd)/count(distinct website_sessions.website_session_id) As Revenue_Per_session,
sum(orders.price_usd)/count(distinct orders.order_id) As Revenue_Per_Order
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id
group by 1,2;
/*Overall convertion rate growth by top two utm source*/

select 
year(website_sessions.created_at) as Year_Wise,
quarter(website_sessions.created_at) As Quartly,
count(distinct case when website_sessions.utm_source ='gsearch' and website_sessions.utm_campaign ='nonbrand' then orders.order_id else null end)
/count(distinct case when website_sessions.utm_source ='gsearch' and website_sessions.utm_campaign ='nonbrand' then website_sessions.website_session_id else null end)
as Gsearch_Nonbrand_Convertion_Rate,
count(distinct case when website_sessions.utm_source='bsearch' and website_sessions.utm_campaign='nonbrand' then orders.order_id else null end)
/count(distinct case when website_sessions.utm_source='bsearch' and website_sessions.utm_campaign='nonbrand' then website_sessions.website_session_id else null end)
 as Bsearch_Nonbrand_Convertion_Rate,
 count(distinct case when  website_sessions.utm_campaign='brand' then orders.order_id else null end)
/count(distinct case when website_sessions.utm_campaign='brand' then website_sessions.website_session_id else null end)
 as Brand_search_Convertion_Rate,
  count(distinct case when  website_sessions.utm_source is null and website_sessions.http_referer is not null  then orders.order_id else null end)
/count(distinct case when  website_sessions.utm_source is null and website_sessions.http_referer is not null then website_sessions.website_session_id else null end)
 as Organic_search_Convertion_Rate,
   count(distinct case when  website_sessions.utm_source is null and website_sessions.http_referer is null  then orders.order_id else null end)
/count(distinct case when  website_sessions.utm_source is null and website_sessions.http_referer is  null then website_sessions.website_session_id else null end)
 as Direc_Type_search_Convertion_Rate
from website_sessions
left join orders on website_sessions.website_session_id=orders.website_session_id
group by 1,2
order by 1,2; 

/*Monthly Trending Analysis for Revenue and margin by each product*/
select
year(created_at) As Year_Wise,
monthname(created_at) As Month_Wise,
sum(case when primary_product_id=1 then price_usd else null end) As Birthday_Gifts_Revenue,
sum(case when primary_product_id=1 then price_usd-cogs_usd else null end) As Birthday_Gifts_Margin,
sum(case when primary_product_id =2 then price_usd else null end) As Valentine_Gifts_Revenue,
sum(case when primary_product_id=2 then price_usd-cogs_usd else null end) As Valentine_Gifts_Margin,
sum(case when primary_product_id =3 then price_usd else null end) As Jwellery_Gifts_Revenue,
sum(case when primary_product_id=3 then price_usd-cogs_usd else null end) As Jwellery_Gifts_Margin,
sum(case when primary_product_id =4 then price_usd else null end) As New_launch_product_Revenue,
sum(case when primary_product_id=4 then price_usd-cogs_usd else null end) As New_launch_product_Margin,
sum(price_usd) as Total_Revenue,
sum(price_usd-cogs_usd) as Overall_Margin
from orders
group by 1,2;


























