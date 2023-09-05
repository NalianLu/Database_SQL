# *****************************************************************************
# MySQL9_Python_SQL.py
# *****************************************************************************
import pymysql
import pandas as pd
import time
from datetime import datetime

def parse_sql(file_name):
  # Open, readlines and close the SQL fil
  sql_file = open(file_name, 'r')
  sql_string = sql_file.readlines()
  sql_file.close()

  # Loop line by line skipping comments and striping newline characters
  # We are assuming a single statement in the SQL file
  # It was manually confirmed there are spaces in the right places
  # Tabs were ignored (but probably should not be)
  sql_stmt = ''
  ln_cnt = 0
  for line in sql_string:
    # **********************************************************************
    # *** Step 1: Create a line counter and use it to skip the first 75 or so
    # lines in the SQL file.
    # **********************************************************************
    ln_cnt += 1
    if ln_cnt > 75:
      if line.startswith('--'):
        continue
      else:
        sql_stmt += line.rstrip('\n')
  return sql_stmt

def sql_readings(c):
  # Connect to readings database
  db_conn = pymysql.connect(user=c['user'], passwd=c['passwd'], db=c['db'])

  # Get database cursor
  db_cursor = db_conn.cursor()
  db_cursor.execute('SET SQL_MODE=ANSI_QUOTES')

  # Run SQL code and retrieve the final result into Python
  # Parse the SQL string from the SQL file
  sql_string = parse_sql('MySQL9_Python_SQL.sql')
  # print(sql_string)
  db_cursor.execute(sql_string)
  cfm_kW_freq_recs = db_cursor.fetchall()

  # **********************************************************************
  # *** Step 2: Create cfm_kW_freq_df data frame from cfm_kW_freq_recs
  # records with appropriate column names (see Excel) and print the result
  # to the console. Document execution in SQL sheet of the Excel file.
  # **********************************************************************
  cfm_kW_freq_df = pd.DataFrame(cfm_kW_freq_recs)
  cfm_kW_freq_df.columns = ['cfm_kW_bins', 'cfm_kW_freq']
  # print(cfm_kW_freq_df.info())
  print(cfm_kW_freq_df)

  # Close database connection
  db_conn.close()

def py_readings(c):
  # Connect to readings database
  db_conn = pymysql.connect(user=c['user'], passwd=c['passwd'], db=c['db'])

  # Get database cursor
  db_cursor = db_conn.cursor()
  db_cursor.execute('SET SQL_MODE=ANSI_QUOTES')

  # Fetch the entire readings data set into readings_df data frame
  # and then perform the analysis
  db_cursor.execute("SELECT * FROM readings")
  readings_recs = db_cursor.fetchall()

  # **********************************************************************
  # *** Step 3: Create readings_df data frame from readings_recs and name
  # the columns to match the table headers. Calculate the total kW and
  # CFM/kW and add these columns to the dataframe as total_kW and cfm_kW.
  # Rename air_flow as cfm and make sure both cfm and cfm_kW columns are
  # rounded to 2 decimals.
  # **********************************************************************
  readings_df = pd.DataFrame(readings_recs)
  readings_df.columns = ['readingid', 'reading_dt', 'comp1_kW', 'comp2_kW',
                         'comp3_kW', 'pressure', 'air_flow']
  # print(readings_df.info())

  readings_df['total_kW'] = (readings_df['comp1_kW'] + readings_df['comp2_kW']
                             + readings_df['comp3_kW']).round(2)
  readings_df['cfm'] = readings_df['air_flow'].round(2)
  readings_df['cfm_kW'] = (readings_df['cfm'] / readings_df['total_kW']).round(2)

  # **********************************************************************
  # *** Step 4: Redefine readings_df by removing CFMs/kW < 3 or > 10
  # **********************************************************************
  readings_df = readings_df[ (readings_df['cfm_kW'] >= 3) & (readings_df['cfm_kW'] <= 10) ]
  # print(readings_df.head())


  # **********************************************************************
  # *** Step 5: Research pd.cut() if this is the way you want to proceed,
  # and then define the bins and labels (see Excel) as appropriate.
  # **********************************************************************
  cfm_bins = list(range(3,11))
  cfm_labels = [str(x)+'-'+str(x+1)+' CFM/kW' for x in cfm_bins[:-1]]
  

  # **********************************************************************
  # *** Step 6: Use pd.cut(), if this is your approach, to create the
  # label column for each row of the readings_df data frame.
  # **********************************************************************
  readings_df['cfm_kW_bins'] = pd.cut(readings_df['cfm_kW'], cfm_bins,
                                      include_lowest=True, right=False,
                                      labels=cfm_labels)
  # print(readings_df.head())

  # **********************************************************************
  # *** Step 7: Use value_counts() to count distinct label values and
  # sort the result appropriately. Document execution in SQL sheet of the 
  # Excel file.
  # **********************************************************************
  print(readings_df['cfm_kW_bins'].value_counts().sort_index())

  # Close the connection
  db_conn.close()

def main():
  # Edit connection dictionary with your password and correct airport_db name
  conn_dict = {'user': 'root', 'passwd': '58749516_Lnla561', 'db': 'readings'}

  # Record the time before the function call
  start_time = time.time()
  s_time = datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S')
  print('-----------------------------------------------------------------------')
  print('Running sql_readings started at ' + str(s_time))
  print('-----------------------------------------------------------------------')
  sql_readings(conn_dict)
  # Record the time after the function call
  end_time = time.time()
  e_time = datetime.fromtimestamp(end_time).strftime('%Y-%m-%d %H:%M:%S')
  time_diff = round(end_time - start_time, 0)
  print('-----------------------------------------------------------------------')
  print('It took ' + str(time_diff) + ' seconds, ending at ', str(e_time))
  print('-----------------------------------------------------------------------')

  # Record the time before the function call
  start_time = time.time()
  s_time = datetime.fromtimestamp(start_time).strftime('%Y-%m-%d %H:%M:%S')
  print('-----------------------------------------------------------------------')
  print('Running py_readings started at ' + str(s_time))
  print('-----------------------------------------------------------------------')
  py_readings(conn_dict)
  # Record the time after the function call
  end_time = time.time()
  e_time = datetime.fromtimestamp(end_time).strftime('%Y-%m-%d %H:%M:%S')
  time_diff = round(end_time - start_time, 0)
  print('-----------------------------------------------------------------------')
  print('It took ' + str(time_diff) + ' seconds, ending at ', str(e_time))
  print('-----------------------------------------------------------------------')

# Call the main
if __name__ == '__main__':
  main()
