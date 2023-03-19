"""
Student name(s): Jeff Chen
Student email(s): cchen8@caltech.edu
TODO: High-level program overview

******************************************************************************
This is a template you may start with for your Final Project application.
You may choose to modify it, or you may start with the example function
stubs (most of which are incomplete).

Some sections are provided as recommended program breakdowns, but are optional
to keep, and you will probably want to extend them based on your application's
features.

TODO:
- Make a copy of app-template.py to a more appropriately named file. You can
  either use app.py or separate a client vs. admin interface with app_client.py,
  app_admin.py (you can factor out shared code in a third file, which is
  recommended based on submissions in 22wi).
- For full credit, remove any irrelevant comments, which are included in the
  template to help you get started. Replace this program overview with a
  brief overview of your application as well (including your name/partners name).
  This includes replacing everything in this *** section!
******************************************************************************
"""
# TODO: Make sure you have these installed with pip3 if needed
import sys  # to print error messages to sys.stderr
import os   # to clean screen
from time import sleep
import mysql.connector
# To get error codes from the connector, useful for user-friendly
# error-handling
import mysql.connector.errorcode as errorcode

# Debugging flag to print errors when debugging that shouldn't be visible
# to an actual client. ***Set to False when done testing.***
DEBUG = True


# ----------------------------------------------------------------------
# SQL Utility Functions
# ----------------------------------------------------------------------
def get_conn():
    """"
    Returns a connected MySQL connector instance, if connection is successful.
    If unsuccessful, exits.
    """
    try:
        conn = mysql.connector.connect(
          host='localhost',
          user='appadmin',
          # Find port in MAMP or MySQL Workbench GUI or with
          # SHOW VARIABLES WHERE variable_name LIKE 'port';
          port='3306',  # this may change!
          password='adminpw',
        #   database='pokedb' # replace this with your database name
          database='final_project'
        )
        print('Successfully connected.')
        return conn
    except mysql.connector.Error as err:
        # Remember that this is specific to _database_ users, not
        # application users. So is probably irrelevant to a client in your
        # simulated program. Their user information would be in a users table
        # specific to your database; hence the DEBUG use.
        if err.errno == errorcode.ER_ACCESS_DENIED_ERROR and DEBUG:
            sys.stderr('Incorrect username or password when connecting to DB.')
        elif err.errno == errorcode.ER_BAD_DB_ERROR and DEBUG:
            sys.stderr('Database does not exist.')
        elif DEBUG:
            sys.stderr(err)
        else:
            # A fine catchall client-facing message.
            sys.stderr('An error occurred, please contact the administrator.')
        sys.exit(1)

def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print('Good bye!')
    exit()

def get_trainers():
    try:
        cursor = conn.cursor()
        sql = 'SELECT trainer_id, trainer_name \
                FROM trainer;'
        cursor.execute(sql)
        for trainer_id, trainer_name in cursor.fetchall():
            print(' (%d) - %s'%(trainer_id, trainer_name))
    except Exception as e:
        print(e)
    finally:
        cursor.close()

def del_trainers(id):
    try:
        cursor = conn.cursor()
        sql = 'DELETE FROM trainer WHERE trainer_id=%d;'%int(id)
        cursor.execute(sql)
        conn.commit()
    except Exception as e:
        print(e)
    finally:
        cursor.close()

def main():
    """
    Main function for starting things up.
    """
    while True:
        trainers = get_trainers()
        print(' (q) - quit')
        del_id = input('select a trainer to delete: ')
        if del_id=='q': break
        del_trainers(del_id)
    quit_ui()


if __name__ == '__main__':
    # This conn is a global object that other functions can access.
    # You'll need to use cursor = conn.cursor() each time you are
    # about to execute a query with cursor.execute(<sqlquery>)
    conn = get_conn()
    main()
