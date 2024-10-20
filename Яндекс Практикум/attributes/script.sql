- language: SQL
negative_pattern: '(?i:begin|boolean|package|exception)'

WITH cte AS (  
SELECT user_id  
  FROM stackoverflow.posts  
 GROUP BY user_id  
 ORDER BY COUNT(id) DESC  
 LIMIT 1)   

SELECT EXTRACT(WEEK FROM p.creation_date) AS week,  
       MAX(p.creation_date) as date  
  FROM stackoverflow.posts p  
  JOIN cte ON cte.user_id = p.user_id  
 WHERE DATE_TRUNC('month', p.creation_date)::date = '2008-10-01'  
 GROUP BY EXTRACT(WEEK FROM p.creation_date); 
