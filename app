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
                sql = 'CALL write_price_history(%s, %s, %s, %s, %s, %s, %s)'
                pair = row[1]
                # TODO not all currencies will be 3 letter abbrevs, figure out a way to fix
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
            if curr['abbrev'].lower() == currency.lower():
                return True, curr['abbrev']
            elif curr['name'].lower() == currency.lower():
                return True, curr['name']
        return False

def clear_data(connection):
    with connection.cursor() as cursor:
        sql = 'TRUNCATE TABLE `price_history`'
        cursor.execute(sql)
        connection.commit()

def get_user_id_from_name(conn, name):
    with conn.cursor() as cursor:
        sql = 'SELECT get_user_id(%s)'
        cursor.execute(sql, (name))
        result = cursor.fetchone()
        # Result is a dictionary with function+params as key.
        # We only need the first result (there should only be 1)
        for key in result:
            return int(result[key])
        return -1

def create_whale_watch(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    valid = False

    # Get required info from user
    while not valid:
        currency = input('Please enter the currency to whale watch: ')
        alert_amt = int(input('Please enter the alert limit for the whale watch: '))
        valid_curr, stored_curr = validate_currency(conn, currency)
        valid_alert = alert_amt > 0
        valid = valid_curr and valid_alert
        if not valid:
            print('Invalid values received. Please try again.')
        else:
            # Use stored values to prevent capitalization errors
            currency = stored_curr
    sql = 'CALL create_whale_watch(%s, %s, %s)'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id, currency, alert_amt))
        conn.commit()
        print('Successfully added whale watch.')

def create_price_watch(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    valid = False

    # Get required info from user
    while not valid:
        base = input('Please enter the base currency (currency that the target currency will be denominated in): ')
        target = input('Please enter the target currency (currency you want to watch): ')
        base_amount = int(input('Please enter the base currency amount: '))

        valid_base, stored_base = validate_currency(conn, base)
        valid_target, stored_targ = validate_currency(conn, target)
        valid_base_amt = base_amount > 0
        valid = valid_base and valid_target and valid_base_amt
        if not valid:
            print('Invalid values received. Please try again.')
        else:
            # Use stored values to prevent capitalization errors
            base = stored_base
            target = stored_targ
    sql = 'CALL create_price_watch(%s, %s, %s, %s, %s)'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id, base, target, base_amount))
        conn.commit()
        print('Successfully added price watch.')

def check_whale_watches(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    sql = 'SELECT `currency`, `alert_amount` FROM `whale_watch` WHERE `watcher_id` = %s AND `criteria_met` = 1'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        if results:
            print('\nActivated whale watches:')
            print(*results)
        else:
            print('\nNo whale watches were activated')

def check_price_watches(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    sql = 'SELECT `base_currency`, `base_amount`, `target_currency` FROM `price_watch` WHERE `watcher_id` = %s AND `criteria_met` = 1'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        if results:
            print('\nActivated price watches:')
            print(*results)
        else:
            print('\nNo price watches were activated')

def delete_price_watch(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    sql = 'SELECT `id`, `base_currency`, `base_amount`, `target_currency` FROM `price_watch` WHERE `watcher_id` = %s'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        if results:
            curr_idx = 1
            idx_to_id = {}
            for r in results:
                watch_id = r.pop('id', None)
                idx_to_id[curr_idx] = watch_id
                print(str(curr_idx) + ':', r)
                curr_idx += 1

            print('\nEnter number of price watch to delete, or 0 for all')
            answer = int(input('> '))
            while answer < 0 or answer > curr_idx:
                print('Invalid input. Please try again.')
                answer = int(input('> '))
            if answer == 0:
                id_to_delete = user_id
                sql = 'DELETE FROM `price_watch` WHERE `watcher_id` = %s'
            else:
                id_to_delete = idx_to_id[answer]
                sql = 'DELETE FROM `price_watch` WHERE `id` = %s'
            cursor.execute(sql, (id_to_delete))
            conn.commit()
            print('Successfully deleted price watch')
        else:
            print('\nNo price watches found')

def delete_whale_watch(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    sql = 'SELECT `id`, `currency`, `alert_amount` FROM `whale_watch` WHERE `watcher_id` = %s'
    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        if results:
            curr_idx = 1
            idx_to_id = {}
            for r in results:
                watch_id = r.pop('id', None)
                idx_to_id[curr_idx] = watch_id
                print(str(curr_idx) + ':', r)
                curr_idx += 1

            print('\nEnter number of whale watch to delete, or 0 for all')
            answer = int(input('> '))
            while answer < 0 or answer > curr_idx:
                print('Invalid input. Please try again.')
                answer = int(input('> '))
            if answer == 0:
                id_to_delete = user_id
                sql = 'DELETE FROM `whale_watch` WHERE `watcher_id` = %s'
            else:
                id_to_delete = idx_to_id[answer]
                sql = 'DELETE FROM `whale_watch` WHERE `id` = %s'
            cursor.execute(sql, (id_to_delete))
            conn.commit()
            print('Successfully deleted whale watch')
        else:
            print('\nNo whale watches found')

def watch_sub_prompt(conn, funcs):
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
        funcs['create'](conn)
        return False
    elif sub_answer == 2:
        funcs['check'](conn)
        return False
    else:
        funcs['delete'](conn)
        return False

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
        funcs = {'create': globals()['create_price_watch'], 'check': globals()['check_price_watches'], 'delete': globals()['delete_price_watch']}
        return watch_sub_prompt(conn, funcs)
    elif answer == 2:
        funcs = {'create': globals()['create_whale_watch'], 'check': globals()['check_whale_watches'], 'delete': globals()['delete_whale_watch']}
        return watch_sub_prompt(conn, funcs)
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
