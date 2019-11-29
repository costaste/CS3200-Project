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