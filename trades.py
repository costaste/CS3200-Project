from utils import validate_currency, get_user_id_from_name

def trade_sub_prompt(conn):
    user_name = input('Please enter your name: ')
    user_id = get_user_id_from_name(conn, user_name)

    valid = False

    while not valid:
        base = input('Please enter the base currency of your trade: ')
        base_amt = input('Please enter the amount of this currency you traded: ')
        target = input('Please enter the target currency of your trade: ')
        target_amt = input('Please enter the amount of this currency you received: ')


        valid_base, stored_base = validate_currency(conn, base)
        valid_target, stored_targ = validate_currency(conn, target)
        # Use stored values to prevent capitalization errors
        base = stored_base if valid_base else base
        target = stored_targ if valid_target else target
        try:
            base_amt = int(base_amt)
            target_amt = int(target_amt)
            valid_base_amt = base_amt > 0
            valid_target_amt = target_amt > 0
        except:
            valid_base_amt = False
            valid_target_amt = False
        valid = valid_base and valid_target and valid_base_amt and valid_target_amt
        if not valid:
            print('Invalid values received. Please try again.')

    buyer_name = input('Please enter the other participant in the trade: ')
    buyer_id = get_user_id_from_name(conn, buyer_name)

    with conn.cursor() as cursor:
        sql = 'CALL create_trade(%s, %s, %s, %s, %s, %s)'
        cursor.execute(sql, (buyer_id, user_id, base, target, base_amt, target_amt))
        conn.commit()
        print('\nSuccessfully added trade.')
    return False
