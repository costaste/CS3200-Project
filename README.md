# CryptoTracker

A command line app written in Python that allows users to view historical information about cryptocurrencies, enter trades they participated in, and create and manage price & whale watches.
This project was completed for the class CS3200: Database Design at Northeastern University. Work was completed by Stephen Costa, Timothy Mitchell, and Matthew Crowley.

All data was taken for free from [http://www.cryptodatadownload.com/](http://www.cryptodatadownload.com/). It is in the `.csv` file format and imported into the app via the `csv` Python library. We used the `pymysql` library to handle interaction with the database.

Currently this is only run locally and with data downloaded manually from that site. At some point it'd be an improvement to host this database and use an API to fetch the data

## Setup & Run
- Install Python [here](https://www.python.org/downloads/) or use your OS's package manager
- Install PyMySql using pip [(docs)](https://pymysql.readthedocs.io/en/latest/user/installation.html)
- Install MySql [here](https://www.mysql.com/downloads/)
- Install Tabulate using pip [(docs)](https://pypi.org/project/tabulate/)
- Clone this repository
- Run the `create_database.sql` file that's in the root directory of this repository
- Navigate to this repository's directory in your terminal app of preference
- Run `./app` or `python app` and sign in with whichever user you've added to you local MySql server
- That's it!
