#!/usr/bin/env python3

from getpass import getpass
import csv
import os
import pymysql
import sys

SERVER = 'localhost'
DB     = 'cryptotracker'

def connect_db(username, pw):
    return pymysql.connect(host=SERVER, user=username, password=pw, db=DB, port=3306, cursorclass=pymysql.cursors.DictCursor)

def prompt_username_pw():
    username = input('Please enter mysql username: ')
    password = getpass('Please enter mysql password: ')
    return (username, password)

def import_data(connection, file_name):
    row_num = 0
    print('Importing data from: ' + file_name)
    with open(file_name, 'r') as csvfile:
        reader = csv.reader(csvfile, delimiter=',')
        with connection.cursor() as cursor:
            for row in reader:
                # First 2 lines don't contain data
                if row_num < 2:
                    row_num += 1
                    continue
                # Create a new record
                sql = 'INSERT INTO `price_history` (`price_date`, `high`, `low`, `day_open`, `day_close`) VALUES (%s, %s, %s, %s, %s)'
                cursor.execute(sql, (row[0], row[3], row[4], row[2], row[5]))
            connection.commit()

def clear_data(connection):
    with connection.cursor() as cursor:
        sql = 'TRUNCATE TABLE `price_history`'
        cursor.execute(sql)
        connection.commit()


def main():
    conn = None
    try:
        username, password = prompt_username_pw()
        # Print empty line to separate next statements
        print('')
        conn = connect_db(username, password)
    except:
        print('Invalid credentials.')
        return 0

    # Import all data files
    for filename in os.listdir('./data/'):
        import_data(conn, './data/' + filename)

    conn.close()
    return 0

if __name__ == '__main__':
    sys.exit(main())