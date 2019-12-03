from enum import Enum
from tabulate import tabulate

from utils import validate_currency, get_user_id_from_name

class WatchType(Enum):
    PRICE = 0
    WHALE = 1

def watch_sub_prompt(conn, watch):
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
        __create_watch(conn, watch)
        return False
    elif sub_answer == 2:
        __check_watches(conn, watch)
        return False
    else:
        __delete_watch(conn, watch)
        return False

def __create_watch(conn, watch):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    valid = False

    # Get required info from user
    while not valid:
        if watch == WatchType.PRICE:
            valid, inputs = __price_input(conn)
            sql = 'CALL create_price_watch(%s, %s, %s, %s)'
        else:
            valid, inputs = __whale_input(conn)
            sql = 'CALL create_whale_watch(%s, %s, %s)'
        if not valid:
            print('Invalid values received. Please try again.')

    with conn.cursor() as cursor:
        inputs = (user_id,) + inputs
        cursor.execute(sql, inputs)
        conn.commit()
        watch_str = ' price ' if watch == WatchType.PRICE else ' whale '
        print('\nSuccessfully added' + watch_str + 'watch.')

def __check_watches(conn, watch):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    if watch == WatchType.PRICE:
        sql = 'CALL get_activated_price_watches(%s)'
        watch_str = ' price '
    else:
        sql = 'CALL get_activated_whale_watches(%s)'
        watch_str = ' whale '

    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        if results:
            print('\nActivated' + watch_str + 'watches:')
            print(tabulate(results, headers='keys', tablefmt='psql'))
        else:
            print('\nNo' + watch_str + 'watches were activated')

def __delete_watch(conn, watch):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    if watch == WatchType.PRICE:
        sql = 'CALL get_price_watches_for_user(%s)'
        table = '`price_watch`'
        watch_str = ' price '
    else:
        sql = 'CALL get_whale_watches_for_user(%s)'
        table = '`whale_watch`'
        watch_str = ' whale '

    with conn.cursor() as cursor:
        cursor.execute(sql, (user_id))
        results = cursor.fetchall()
        row_idxs = []
        if results:
            curr_idx = 1
            idx_to_id = {}
            for r in results:
                watch_id = r.pop('id', None)
                idx_to_id[curr_idx] = watch_id
                row_idxs.append(curr_idx)
                curr_idx += 1

            print(tabulate(results, headers='keys', tablefmt='psql', showindex=row_idxs))
            print('\nEnter number of' + watch_str + 'watch to delete, or 0 for all')
            answer = int(input('> '))
            while answer < 0 or answer > curr_idx:
                print('Invalid input. Please try again.')
                answer = int(input('> '))

            id_to_delete = idx_to_id[answer] if answer != 0 else user_id
            id_type = '`id`' if answer != 0 else '`watcher_id`'
            sql = 'CALL delete_watches(%s, %s, %s)'
            cursor.execute(sql, (id_to_delete, table, id_type))
            conn.commit()
            print('\nSuccessfully deleted' + watch_str + 'watch')
        else:
            print('\nNo' + watch_str + 'watches found')

def __whale_input(conn):
    currency = input('Please enter the currency to whale watch: ')
    alert_amt = input('Please enter the alert limit for the whale watch: ')

    valid_curr, stored_curr = validate_currency(conn, currency)
    try:
        alert_amt = int(alert_amt)
        valid_alert = alert_amt > 0
    except:
        valid_alert = False

    # Use stored values to prevent capitalization errors
    currency = stored_curr if valid_curr else currency
    alert_amt = alert_amt if not valid_alert else int(alert_amt)

    valid = valid_curr and valid_alert
    inputs = (currency, alert_amt)
    return valid, inputs

def __price_input(conn):
    base = input('Please enter the base currency (currency that the target currency will be denominated in): ')
    target = input('Please enter the target currency (currency you want to watch): ')
    base_amount = input('Please enter the base currency amount: ')

    valid_base, stored_base = validate_currency(conn, base)
    valid_target, stored_targ = validate_currency(conn, target)
    try:
        base_amount = int(base_amount)
        valid_base_amt = base_amount > 0
    except:
        valid_base_amt = False

    # Use stored values to prevent capitalization errors
    base = stored_base if valid_base else base
    target = stored_targ if valid_target else target

    valid = valid_base and valid_target and valid_base_amt
    inputs = (base, target, base_amount)
    return valid, inputs
