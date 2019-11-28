#!/usr/bin/env python3

from getpass import getpass
import csv
import os
import pymysql
import sys

SERVER = 'localhost'
DB     = 'cryptotracker'

# TODO replace sql with procedures/funcs/triggers
# NOTES:
#   - can use a trigger to set price watch criteria_met to 1

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
        sql = 'SELECT * FROM `currencies`'
        cursor.execute(sql)
        currencies = cursor.fetchall()
        for curr in currencies:
            if curr['abbrev'] == currency or curr['name'] == currency:
                return True
        return False

def clear_data(connection):
    with connection.cursor() as cursor:
        sql = 'TRUNCATE TABLE `price_history`'
        cursor.execute(sql)
        connection.commit()

def get_user_id_from_name(conn, name):
    with conn.cursor() as cursor:
        sql = 'SELECT `id` from users WHERE `name` = %s'
        cursor.execute(sql, (name))
        result = cursor.fetchone()
        if result:
            return int(result['id'])
        # If user doesn't exist, create entry
        sql = 'INSERT INTO `users` (`name`) VALUES (%s)'
        cursor.execute(sql, (name))
        conn.commit()
        # Get newly created user
        return get_user_id_from_name(conn, name)

def create_price_watch(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    valid = False

    while not valid:
        base = input('Please enter the base currency (currency that the target currency will be denominated in): ')
        target = input('Please enter the target currency (currency you want to watch): ')
        base_amount = int(input('Please enter the base currency amount: '))
        target_amount = input('Please enter the target amount (default 1): ')
        target_amount = 1 if not target_amount else int(target_amount)
        valid_base = validate_currency(conn, base)
        valid_target = validate_currency(conn, target)
        valid_base_amt = base_amount > 0
        valid_target_amt = target_amount > 0
        valid = valid_base and valid_target and valid_base_amt and valid_target_amt
        if not valid:
            print('Invalid values received. Please try again.')
    sql = 'INSERT INTO `price_watch` (`watcher_id`, `base_currency`, `target_currency`, `base_amount`, `target_amount`, `criteria_met`) VALUES (%s, %s, %s, %s, %s, %s)'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id, base, target, base_amount, target_amount, 0))
        conn.commit()
        print('Successfully added price watch.')


def menu_prompt(conn):
    prompt = '\nWelcome to CryptoTracker. What would you like to do?\n\n'
    prompt += '1. Create\Check\Delete price watch\n'
    prompt += '2. Create\Check\Delete whale watch\n'
    prompt += '3. View information about a currency\n'
    prompt += '4. Enter a trade\n'
    prompt += '5. Exit\n'

    print(prompt)
    answer = int(input('Please enter the number of the menu option you wish to complete: '))

    while answer < 1 or answer > 5:
        print('\nInvalid input. Please try again.')
        print(prompt)
        answer = int(input('Please enter the number of the menu option you wish to complete: '))

    if answer == 1:
        sub_answer = 0
        while sub_answer < 1 or sub_answer > 3:
            prompt = 'Which would you like to do?\n'
            prompt += '1. Create\n'
            prompt += '2. Check\n'
            prompt += '3. Delete\n'
            print(prompt)
            sub_answer = int(input('> '))
            if sub_answer < 1 or sub_answer > 3:
                print('\nInvalid input. Please try again.')
        if sub_answer == 1:
            create_price_watch(conn)
            return False
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

    os.system('cls' if os.name == 'nt' else 'clear')
    should_exit = menu_prompt(conn)
    while not should_exit:
        should_exit = menu_prompt(conn)

    conn.close()
    return 0

if __name__ == '__main__':
    sys.exit(main())