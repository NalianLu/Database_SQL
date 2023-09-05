-- **********************************************************************
-- Python and SQL Connectivity
-- **********************************************************************
-- BACKGROUND:
-- CompAir's chief engineer requested that we provide a rough analysis on 
-- one of our client's air flow generation efficiency in their main 
-- production facility. Specifically, he wants some idea on the distribution 
-- of the ratio of the air flow produced in CFMs or Cubic Feet per Minute 
-- divided by the total power needed to generate that air flow to see if it 
-- is averaging about 6-7 CFMs per 1 kW of power. Observations under 3 or
-- over 10 CFMs/kW are typically considered errouneous, regardless of the
-- type of compressor, we will use those values as control limits later.
-- This analysis would allow the client to examine efficiency of its air 
-- production system with potential for cost savings and improved power 
-- management benefits. If the analysis proves worth while, CompAir would 
-- expand it to all other facilities for this client, and also offer this 
-- type of analysis to a substantial number of our other clients with  
-- similar needs, all of which could result in processing of a potentially 
-- huge volume of air flow logger data.
-- **********************************************************************
-- DATA: 
-- Run readings.sql to extract the 6,304,227 readings of a compressed air 
-- system over the course of a year. Most of the data is real, but there 
-- were missing observations and entire weeks when the logger was down, so
-- some of the data was imputed using other data to make for a continous 
-- year worth of observations.
-- **********************************************************************

-- ANALYSIS:
-- Examine the ratio between the air flow production and total power needed
-- to generate that air flow, aka cfm_kW for the month of January to get 
-- the idea of the range of values, observe some junky data such as 16,270
-- negative readings, as well as low readings not close to the control limits.
-- Using 3 CFMs/kW, we get 89550 January observations to potentially discard, 
-- which translates into 781,726, which at 12.5% is a substantial amount.
WITH CFM_kW AS (
SELECT reading_dt, 
  ROUND(comp1_kW + comp2_kW + comp3_kW, 2) AS total_kW, 
  ROUND(air_flow, 2) AS cfm, 
  ROUND(air_flow / (comp1_kW + comp2_kW + comp3_kW), 2) AS cfm_kW
FROM readings
)
SELECT * FROM CFM_kW
WHERE MONTH(reading_dt) = 1 AND cfm / total_kW < 0; -- Change from 0 to 3

-- Use the CTE below to examine the average cfm_kW by month, and you shoud
-- see that June and September have an average that is 3 time's as high
-- indicating potentially a substantial number of incorrect readings.
WITH CFM_kW AS (
SELECT reading_dt, 
  ROUND(comp1_kW + comp2_kW + comp3_kW, 2) AS total_kW, 
  ROUND(air_flow, 2) AS cfm, 
  ROUND(air_flow / (comp1_kW + comp2_kW + comp3_kW), 2) AS cfm_kW
FROM readings
) SELECT MONTH(reading_dt) AS read_mth, 
    ROUND(AVG(cfm_kW), 2) AS avg_cfm_kW
  FROM CFM_kW 
  GROUP BY read_mth;

-- Examine June readings to get an idea on what is going on. Start by 
-- filtering cfm_kW > 10 getting, giving you 6748 June observations to 
-- potentially discard, which translates into 121,689 or about 2% of all 
-- observations, which together with the low values above, add up to
-- almost 15% of the entire dataset.
WITH CFM_kW AS (
  SELECT reading_dt, 
    ROUND(comp1_kW + comp2_kW + comp3_kW, 2) AS total_kW, 
    ROUND(air_flow, 2) AS cfm, 
    ROUND(air_flow / (comp1_kW + comp2_kW + comp3_kW), 2) AS cfm_kW
  FROM readings
)
SELECT * FROM CFM_kW
WHERE MONTH(reading_dt) = 6 AND cfm / total_kW > 10;
	
-- Examine CFM_kW2 CTE excluding low < 3 or high > 10 readings (> vs. >=
-- and < vs. <= distinctions are not important). Run the frequency table
-- with 1 CFM/kW increments, opy/paste the result into Excel and create a 
-- bar chart without gaps to show the distribution.
WITH CFM_kW AS (
  SELECT reading_dt, 
    ROUND(comp1_kW + comp2_kW + comp3_kW, 2) AS total_kW, 
    ROUND(air_flow, 2) AS cfm, 
    ROUND(air_flow / (comp1_kW + comp2_kW + comp3_kW), 2) AS cfm_kW 
  FROM readings 
), CFM_kW2 AS ( 
  SELECT * FROM CFM_kW 
  WHERE cfm_kW >= 3 AND cfm_kW <= 10 
) 
SELECT  
  CASE 
    WHEN cfm_kW BETWEEN 3 AND 3.99 THEN '  3-4 CFM/kW' 
	WHEN cfm_kW BETWEEN 4 AND 4.99 THEN '  4-5 CFM/kW' 
    WHEN cfm_kW BETWEEN 5 AND 5.99 THEN '  5-6 CFM/kW' 
    WHEN cfm_kW BETWEEN 6 AND 6.99 THEN '  6-7 CFM/kW' 	
    WHEN cfm_kW BETWEEN 7 AND 7.99 THEN '  7-8 CFM/kW' 
    WHEN cfm_kW BETWEEN 8 AND 8.99 THEN '  8-9 CFM/kW' 
    ELSE '9-10 CFM/kW' 
  END AS cfm_kW_bins, 
  COUNT(*) AS cfm_kW_freq 
FROM CFM_kW2 
GROUP BY cfm_kW_bins  
ORDER BY cfm_kW_bins;
