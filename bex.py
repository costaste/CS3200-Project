import webbrowser
from tabulate import tabulate

def bex_sub_prompt(conn):
    with conn.cursor() as cursor:
        sql = 'CALL get_bexes()'
        cursor.execute(sql)
        results = cursor.fetchall()
        if results:
            idx_to_id = {}
            row_idxs = []
            for idx, r in enumerate(results):
                bex_id = r.pop('id', None)
                idx_to_id[idx] = bex_id
                row_idxs.append(idx)
            print(tabulate(results, headers='keys', tablefmt='psql', showindex=row_idxs))
            print('\nEnter number of block explorer to use')
            answer = int(input('> '))
            while answer not in row_idxs:
                print('Invalid input. Please try again.')
                answer = int(input('> '))
            sql = 'CALL get_bex_search_url(%s)'
            cursor.execute(sql, (idx_to_id[answer]))

            bex = cursor.fetchone()
            search_url = bex['search_url']
            print('Please enter an address, transaction, or block')
            print('An example, the Bitcoin genesis block: 000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f')
            search_query = input('> ')
            webbrowser.open(search_url + search_query)
            return False
