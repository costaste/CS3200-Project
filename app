#!/usr/bin/env python3

from getpass import getpass
import csv
import os
import pymysql
import sys

from watches import WatchType, watch_sub_prompt
from checkCurrency import curr_check_prompt

SERVER = 'localhost'
DB     = 'cryptotracker'

# TODO
#   - menu options 3 & 4
# NOTES:
#   - can use a trigger to set price watch criteria_met to 1

def connect_db(username, pw):
    return pymysql.connect(host=SERVER, user=username, password=pw, db=DB, port=3306, cursorclass=pymysql.cursors.DictCursor)

def prompt_username_pw():
    username = input('Please enter mysql username: ')
    password = getpass('Please enter mysql password: ')
    return (username, password)

def import_data(connection, file_name):
    imported_from = file_name.split("_")[0]
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
                sql = 'CALL write_price_history(%s, %s, %s, %s, %s, %s, %s)'
                pair = row[1]
                # TODO not all currencies will be 3 letter abbrevs, figure out a way to fix
                base = pair[3:]
                target = pair[:3]
                cursor.execute(sql, (row[0], base, target, row[3], row[4], row[2], row[5]))
                row_num += 1
            connection.commit()
            print((row_num - 2), 'records imported.')

def clear_data(connection):
    with connection.cursor() as cursor:
        sql = 'CALL clear_price_history()'
        cursor.execute(sql)
        connection.commit()

def menu_prompt(conn):
    global create_price_watch, check_price_watch, delete_price_watch
    prompt = '\nWelcome to CryptoTracker. What would you like to do?\n\n'
    prompt += '1. Create\Check\Delete price watch\n'
    prompt += '2. Create\Check\Delete whale watch\n'
    prompt += '3. View information about a currency\n'
    prompt += '4. Enter a trade\n'
    prompt += '5. Exit\n'
    prompt += 'Please enter the number of the menu option you wish to complete: \n'

    print(prompt)
    answer = int(input('> '))

    while answer < 1 or answer > 5:
        print('\nInvalid input. Please try again.')
        print(prompt)
        answer = int(input('> '))

    if answer == 1:
        return watch_sub_prompt(conn, WatchType.PRICE)
    elif answer == 2:
        return watch_sub_prompt(conn, WatchType.WHALE)
    elif answer == 3:
        return curr_check_prompt(conn)
    elif answer == 5:
        return True



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

    # Clear screen
    os.system('cls' if os.name == 'nt' else 'clear')

    # Keep prompting user actions until they select exit
    should_exit = menu_prompt(conn)
    while not should_exit:
        should_exit = menu_prompt(conn)

    conn.close()
    return 0

if __name__ == '__main__':
    sys.exit(main())
