#!/usr/bin/env python3

import sys
from getpass import getpass
import pymysql

SERVER = "localhost"
# TODO set up database
DB     = ""

def connect_db(username, pw):
    return pymysql.connect(host=SERVER, user=username, password=pw, db=DB, port=3306, cursorclass=pymysql.cursors.DictCursor)

def prompt_username_pw():
    username = input("Please enter mysql username: ")
    password = getpass("Please enter mysql password: ")
    return (username, password)


def main():
    conn = None
    try:
        username, password = prompt_username_pw()
        conn = connect_db(username, password)
    except:
        print('\nInvalid credentials.')
        return 0


    conn.close()
    return 0

if __name__ == "__main__":
    sys.exit(main())