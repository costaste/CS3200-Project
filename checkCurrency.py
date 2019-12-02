from utils import get_user_id_from_name
from tabulate import tabulate

def curr_check_prompt(conn):
	check_answer = 0
	while check_answer < 1 or check_answer > 2:
		prompt = 'Which currency pair would you like to check?\n'
		prompt += '1. BTC in USD\n'
		prompt += '2. USD in BTC\n'
		print(prompt)
		check_answer = int(input('> '))
		if check_answer < 1 or check_answer > 2:
			print('\nInvalid input. Please try again.')

	if check_answer == 1:
		__check_curr(conn, 'BTC', 'USD')
		return False
	elif check_answer == 2:
		__check_curr(conn, 'USD', 'BTC')
		return False
	else:
		return False

def __check_curr(conn, curr1, curr2):
	sql = 'CALL check_prices(%s, %s)'

	with conn.cursor() as cursor:
		cursor.execute(sql, (curr1, curr2))
		results = cursor.fetchall()
		if results:
			headers = ['Date', 'Base', 'Target', 'High', 'Low', 'Open', 'Close']
			print(tabulate(results, headers="keys", tablefmt = 'psql'))
		else:
			print('\nNo results.')
