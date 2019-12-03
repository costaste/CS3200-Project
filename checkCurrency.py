from utils import get_user_id_from_name
from tabulate import tabulate

def curr_check_prompt(conn):
	curr1 = ""
	curr2 = ""
	valid_curr = ["USD", "BTC", "EUR", "ETH", "XRP", "LTC", "XMR"]
	while curr1 not in valid_curr:
		curr1 = (input('Enter the base currency: '))
		if curr1 not in valid_curr:
			print('\nInvalid input. Please try again.')

	while curr2 not in valid_curr:
		curr2 = (input('Enter the target currency: '))
		if curr2 not in valid_curr:
			print('\nInvalid input. Please try again.')

	source_answer = 0
	source_dict = {1: "Bitfinex", 2: "Cexio", 3: "Coinbase", 4: "Gemini", 5: "Kraken", 6: "Poloniex", 7: "All", 8: "Average"}
	while source_answer < 1 or source_answer > 8:
		prompt = 'Which data source do you want to check?\n'
		prompt += '1. Bitfinex\n'
		prompt += '2. Cexio\n'
		prompt += '3. Coinbase\n'
		prompt += '4. Gemini\n'
		prompt += '5. Kraken\n'
		prompt += '6. Poloniex\n'
		prompt += '7. All\n'
		prompt += '8. Average\n'
		print(prompt)
		source_answer = int(input('> '))
		if source_answer < 1 or source_answer > 8:
			print('\nInvalid input. Please try again.')

	source = source_dict[source_answer]


	__check_curr(conn, curr1, curr2, source)
	return False


def __check_curr(conn, curr1, curr2, source):


	with conn.cursor() as cursor:
		if source == "All":
			sql = 'CALL check_prices_all(%s, %s)'
			cursor.execute(sql, (curr1, curr2))
			results = cursor.fetchall()
			if results:
				headers = ['Date', 'Base', 'Target', 'High', 'Low', 'Open', 'Close', 'Source']
				print(tabulate(results, headers={'price_date': 'Date', 'base': 'Base', 'target': 'Target',
				'high': 'High', 'low': 'Low', 'day_open': 'Open',
				'day_close': 'Close', 'data_source': 'Source'}, tablefmt = 'psql'))
			else:
				print('\nNo results from any source for the given currency pair.')

		elif source != "Average":
			sql = 'CALL check_prices(%s, %s, %s)'
			cursor.execute(sql, (curr1, curr2, source))
			results = cursor.fetchall()
			if results:
				headers = ['Date', 'Base', 'Target', 'High', 'Low', 'Open', 'Close', 'Source']
				print(tabulate(results, headers={'price_date': 'Date', 'base': 'Base', 'target': 'Target',
				'high': 'High', 'low': 'Low', 'day_open': 'Open',
				'day_close': 'Close', 'data_source': 'Source'}, tablefmt = 'psql'))
			else:
				print('\nNo results from that source for the given currency pair.')

		elif source == "Average":
			sql = 'CALL check_prices_avg(%s, %s)'
			cursor.execute(sql, (curr1, curr2))
			results = cursor.fetchall()
			if results:
				print(tabulate(results, headers="keys", tablefmt = 'psql'))
			else:
				print('\nNo results from any source for the given currency pair.')

