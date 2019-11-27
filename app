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
                sql = 'INSERT INTO `price_history` (`price_date`, `base`, `target`, `high`, `low`, `day_open`, `day_close`) VALUES (%s, %s, %s, %s, %s, %s, %s)'
                pair = row[1]
                base = pair[3:]
                target = pair[:3]
                cursor.execute(sql, (row[0], base, target, row[3], row[4], row[2], row[5]))
                row_num += 1
            connection.commit()
            print((row_num - 2), 'records imported.')

def validate_currency(connection, currency):
    with connection.cursor() as cursor:
        sql = 'SELECT `abbrev` FROM `currencies`'
        cursor.execute(sql)
        currencies = cursor.fetchall()
        for curr in currencies:
            if curr == currency:
                return True
        return False

def clear_data(connection):
    with connection.cursor() as cursor:
        sql = 'TRUNCATE TABLE `price_history`'
        cursor.execute(sql)
        connection.commit()

def menu_prompt():
    prompt = '\nWelcome to CryptoTracker. What would you like to do?\n\n'
    prompt += '1. Create\Check\Delete price watch\n'
    prompt += '2. Create\Check\Delete whale watch\n'
    prompt += '3. View information about a currency\n'
    prompt += '4. Enter a trade\n'
    prompt += '5. Exit\n'

    print(prompt)
    answer = int(input('Please enter the number of the menu option you wish to complete: '))

    while (answer < 1 or answer > 5):
        print('\nInvalid input. Please try again.')
        print(prompt)
        answer = int(input('Please enter the number of the menu option you wish to complete: '))


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

    # Clear any current price history data
    clear_data(conn)
    # Import all data files
    for filename in os.listdir('./data/'):
        import_data(conn, './data/' + filename)

    menu_prompt()

    conn.close()
    return 0

if __name__ == '__main__':
    sys.exit(main())