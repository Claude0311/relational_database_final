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
          user='jeff',
          # Find port in MAMP or MySQL Workbench GUI or with
          # SHOW VARIABLES WHERE variable_name LIKE 'port';
          port='3306',  # this may change!
        #   password='adminpw',
          database='final_project' # replace this with your database name
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

# ----------------------------------------------------------------------
# Functions for Command-Line Options/Query Execution
# ----------------------------------------------------------------------
def example_query():
    param1 = ''
    cursor = conn.cursor()
    # Remember to pass arguments as a tuple like so to prevent SQL
    # injection.
    sql = 'SELECT col1 FROM table WHERE col2 = \'%s\';' % (param1, )
    try:
        cursor.execute(sql)
        # row = cursor.fetchone()
        rows = cursor.fetchall()
        for row in rows:
            (col1val) = (row) # tuple unpacking!
            # do stuff with row data
    except mysql.connector.Error as err:
        # If you're testing, it's helpful to see more details printed.
        if DEBUG:
            sys.stderr(err)
            sys.exit(1)
        else:
            # TODO: Please actually replace this :) 
            sys.stderr('An error occurred, give something useful for clients...')



# ----------------------------------------------------------------------
# Functions for Logging Users In
# ----------------------------------------------------------------------
# Note: There's a distinction between database users (admin and client)
# and application users (e.g. members registered to a store). You can
# choose how to implement these depending on whether you have app.py or
# app-client.py vs. app-admin.py (in which case you don't need to
# support any prompt functionality to conditionally login to the sql database)


# ----------------------------------------------------------------------
# Command-Line Functionality
# ----------------------------------------------------------------------
# TODO: Please change these!
def show_options():
    """
    Displays options users can choose in the application, such as
    viewing <x>, filtering results with a flag (e.g. -s to sort),
    sending a request to do <x>, etc.
    """
    print('What would you like to do? ')
    print('  (TODO: provide command-line options)')
    print('  (x) - something nifty to do')
    print('  (x) - another nifty thing')
    print('  (x) - yet another nifty thing')
    print('  (x) - more nifty things!')
    print('  (q) - quit')
    print()
    ans = input('Enter an option: ').lower()
    if ans == 'q':
        quit_ui()
    elif ans == '':
        pass


# Another example of where we allow you to choose to support admin vs. 
# client features  in the same program, or
# separate the two as different app_client.py and app_admin.py programs 
# using the same database.
def show_admin_options():
    """
    Displays options specific for admins, such as adding new data <x>,
    modifying <x> based on a given id, removing <x>, etc.
    """
    print('What would you like to do? ')
    print('  (x) - something nifty for admins to do')
    print('  (x) - another nifty thing')
    print('  (x) - yet another nifty thing')
    print('  (x) - more nifty things!')
    print('  (q) - quit')
    print()
    ans = input('Enter an option: ').lower()
    if ans == 'q':
        quit_ui()
    elif ans == '':
        pass

player_1 = None
player_2 = None
player_1_name = None
player_2_name = None
player_2_offset = ' '*30

def print_log_file():
    datas = get_fighting_status(option=1)
    print_field(datas[player_1][0], datas[player_2][0])
    try:
        cursor = conn.cursor()
        cursor.execute('SELECT msg FROM fight_log WHERE isnew=1')
        for row in cursor.fetchall():
            print(' - ',end='')
            print(row[0])
        print()
        input('hit <enter> to continue')

    except mysql.connector.Error as e:
        print(e)
    finally:
        cursor.close()

def enter_fight():
    try:
        cursor = conn.cursor()
        cursor.callproc('enter_fight', [player_1, player_2])
        os.system('cls')
        print_log_file()

    except mysql.connector.Error as e:
        print(e)
    finally:
        cursor.close()
    
def select_move(pkm_id, cur_pkm, opp_pkm, offset = ''):
    moves = get_moves(pkm_id)
    while True:
        os.system('cls')
        print_field(cur_pkm, opp_pkm)
        print('%swhat will %s do?'%(offset, cur_pkm['name']))
        for index, (mid, mname) in enumerate( moves ):
            print('%s (%d) - %s'%(offset, index+1, mname))
        print('%s (b) - back'%offset)
        print()
        ans = input('%sEnter an option: '%offset)
        if ans=='b': return -1
        elif 1<=int(ans)<=len(moves): 
            print('You choose %s'%moves[int(ans)-1][1])
            return moves[int(ans)-1][0]
        else:
            print('invalid option')
            sleep(1)

def get_moves(pkm_id):
    try:
        row = (pkm_id, None, None, None, None, None, None, None, None)
        cursor = conn.cursor()
        output = cursor.callproc('pkm_move_info', row)
        result = []
        for i in range(4):
            if output[1+i*2] is not None:
                result.append((output[1+i*2], output[1+i*2+1]))
    except mysql.connector.Error as e:
        print(e)
    finally:
        cursor.close()
        return result

    
def select_pokemon(datas, must=False):
    while True:
        os.system('cls')
        isone = datas[0]['id']==player_1
        print(player_1_name if isone else player_2_name)
        print('select or check the pokemon')
        for index, d in enumerate(datas):
            header = ' ' if d['choosen']==0 else '>'
            status = '%3d/%-3d %s'%(d['hp'][0], d['hp'][1], d['status'] or '')
            print('%s(%d) - %-20s %s'%(header, index+1, d['name'], status))
        if not must: print(' (b) - back')
        print()
        ans = input('Enter an option: ')
        try:
            if ans=='b' and not must: return -1
            elif 1<=int(ans)<=len(datas):
                action = print_pkm_info(datas[int(ans)-1])
                if action==1: return datas[int(ans)-1]['id']
            else: 
                print('invalid option')
                sleep(1)
        except:
            print('invalid option')
            sleep(1)

def print_pkm_info(data):
    while True:
        os.system('cls')
        print('Pokemon Info')
        print('###################################')
        print(data['name'])
        print('     %3s/%-3s %s'%(data['hp'][0], data['hp'][1], data['status'] or ''))
        print()
        moves = get_moves(data['id'])
        for _, move in moves:
            print(' - ',end='')
            print(move)
        print()
        print(' * attack   %2d'%data['stat_change']['atk'])
        print(' * defense  %2d'%data['stat_change']['def'])
        print(' * sp. atk  %2d'%data['stat_change']['spatk'])
        print(' * sp. def  %2d'%data['stat_change']['spdef'])
        print(' * speed    %2d'%data['stat_change']['spd'])
        print(' * accuracy %2d'%data['stat_change']['acc'])
        print(' * evasion  %2d'%data['stat_change']['evasion'])
        print('###################################')
        print()
        if data['choosen']==0 and data['hp'][0]>0:
            print(' (s) - switch')
        print(' (b) - back')
        print()
        ans = input('Enter an option: ')
        if ans == 'b': return -1
        elif ans=='s' and data['choosen']==0: return 1
        else: 
            print('invalid option')
            sleep(1)

def get_player_info(player_name):
    try:
        trainer_name = None
        trainer_id = None
        cursor = conn.cursor()
        sql = 'SELECT trainer_id, trainer_name \
                FROM team LEFT JOIN trainer USING(trainer_id)\
                WHERE trainer_name=\'%s\';'%player_name
        cursor.execute(sql)
        for row in cursor.fetchall():
            (trainer_id, trainer_name) = (row)
    except mysql.connector.Error as e:
        print(e)
    finally:
        cursor.close()
        return (trainer_id, trainer_name)

def print_field(pkm_1, pkm_2):
    offset = player_2_offset
    if pkm_1['trainer']==2:
        pkm_1, pkm_2 = pkm_2, pkm_1
    print('%s|%s'% (player_1_name.center(len(offset)), player_2_name.center(len(offset))))
    print('#'*60)
    print('%s|'%offset)
    print('     %-25s|     %s'%(pkm_1['name'], pkm_2['name']))
    print('        %3d/%-3d %-14s|        %3d/%-3d %s'%(pkm_1['hp'][0], pkm_1['hp'][1], pkm_1['status'] or '', pkm_2['hp'][0], pkm_2['hp'][1], pkm_2['status'] or ''))
    print('%s|'%offset)
    print('#'*60)

def player_action(datas, player_me, player_opp, player_name, offset = ''):
    # player one
    move_id = None
    switch_pkm_id = None
    opp_pkm = next(iter([d for d in datas[player_opp] if d['choosen']==1]))
    cur_pkm = next(iter([d for d in datas[player_me] if d['choosen']==1]))
    pkm_name = cur_pkm['name']
    fainted = cur_pkm['hp'][0]==0
    pkm_id = cur_pkm['id']
    while True:
        os.system('cls')
        print_field(cur_pkm, opp_pkm)
        print('%swhat will %s do?'%(offset, player_name))
        if fainted:
            print('%sx(1) - battle (%s fainted)'%(offset, pkm_name))
        else:
            print('%s (1) - battle'%offset)
        print('%s (2) - pokemon'%offset)
        print('%s (3) - run'%offset)
        print()
        try:
            ans = int(input('%sEnter an option: '%offset))
            if ans==1:
                if fainted:
                    print('%sinvalid option, %s fainted'%(offset, pkm_name))
                    sleep(1)
                    continue
                chosen_move = select_move(pkm_id, cur_pkm, opp_pkm, offset)
                if chosen_move != -1: 
                    move_id = chosen_move
                    break
            elif ans==2:
                chosen_pkm = select_pokemon(datas[player_me])
                if chosen_pkm != -1: 
                    switch_pkm_id = chosen_pkm
                    break
            elif ans==3: break
            else:
                print('%sinvalid option'%offset)
                sleep(1)
        except:
            pass
    return (pkm_id, move_id, switch_pkm_id)

def fainted_switch(cur_pkm_id, switch_pkm_id, player_name):
    try:
        os.system('cls')
        cursor = conn.cursor()
        cursor.callproc('handle_switch', [cur_pkm_id, switch_pkm_id, player_name, None])
        # print_log_file()
    except mysql.connector.Error as e:
        print(e)
        sleep(1)
    finally:
        cursor.close()


def one_turn():
    datas = get_fighting_status()
    (pkm_id_1, move_id_1, switch_pokemon_1) = player_action(datas, player_1, player_2, player_1_name)
    (pkm_id_2, move_id_2, switch_pokemon_2) = player_action(datas, player_2, player_1, player_2_name, offset=player_2_offset)
    try:
        os.system('cls')
        cursor = conn.cursor()
        winner = None
        fainted_1 = None
        fainted_2 = None
        output_one_turn = cursor.callproc('one_turn', [pkm_id_1, pkm_id_2, move_id_1, move_id_2, switch_pokemon_1, switch_pokemon_2, None, None, None])
        print_log_file()
        winner = output_one_turn[6]
        fainted_1 = output_one_turn[7]
        fainted_2 = output_one_turn[8]

    except mysql.connector.Error as e:
        print(e)
        sleep(1)
    finally:
        cursor.close()

    if winner is None and (fainted_1==1 or fainted_2==1):
        datas = get_fighting_status()
        if fainted_1==1:
            pkm_id_1 = next(iter([d for d in datas[player_1] if d['choosen']==1]))['id']
            switch_pkm_id_1 = select_pokemon(datas[player_1], must=True)
            fainted_switch(pkm_id_1, switch_pkm_id_1, player_1_name)
        if fainted_2==1:
            pkm_id_2 = next(iter([d for d in datas[player_2] if d['choosen']==1]))['id']
            switch_pkm_id_2 = select_pokemon(datas[player_2], must=True)
            fainted_switch(pkm_id_2, switch_pkm_id_2, player_2_name)
        print_log_file()
    
    return winner
    
def get_fighting_status(option = 0):
    try:
        cursor = conn.cursor()
        datas = {player_1:[], player_2:[]}
        sql = 'SELECT trainer_id, pkm_id, pkm_name, choosen, hp, max_hp, status, atk, def, spatk, spdef, spd, acc, evasion \
            FROM fighting_status NATURAL JOIN pokemon NATURAL JOIN pokedex %s;'%('' if option ==0 else 'WHERE choosen=1')
        cursor.execute(sql)
        for row in cursor.fetchall():
            (trainer_id, pkm_id, pkm_name, choosen, hp, max_hp, status, atk, defense, spatk, spdef, spd, acc, evasion) = (row)
            datas[trainer_id].append({
                'id':pkm_id,
                'trainer':trainer_id,
                'name':pkm_name,
                'choosen':choosen,
                'hp':[hp, max_hp],
                'status': status,
                'stat_change':{
                    'atk':atk,
                    'def':defense,
                    'spatk':spatk,
                    'spdef':spdef,
                    'spd':spd,
                    'acc':acc,
                    'evasion':evasion
                }
            })

        
    except mysql.connector.Error as e:
        print(e)
    finally:
        cursor.close()
        return datas


def quit_ui():
    """
    Quits the program, printing a good bye message to the user.
    """
    print('Good bye!')
    exit()

def player_login():
    global player_1
    global player_2
    global player_1_name
    global player_2_name
    while True:
        player_1_name = input('player 1 login:')
        try:
            # change to CHECK password later
            player_1, player_1_name = get_player_info(player_1_name)
            if player_1==None: raise Exception('trainer not found')
            break
        except:
            print('invalid input')
            continue
    while True:
        print(player_2_offset, end='')
        player_2_name = input('player 2 login:')
        try:
            # change to CHECK password later
            if player_2_name == player_1_name: raise Exception('trainer duplicate')
            player_2, player_2_name = get_player_info(player_2_name)
            if player_2==None: raise Exception('trainer not found')
            break
        except:
            print(player_2_offset, end='')
            print('invalid input')
            continue


def main():
    """
    Main function for starting things up.
    """
    player_login()
    enter_fight()
    while True:
        winner = one_turn()
        if winner in [0,1,2]:
            break
    quit_ui()

if __name__ == '__main__':
    # This conn is a global object that other functions can access.
    # You'll need to use cursor = conn.cursor() each time you are
    # about to execute a query with cursor.execute(<sqlquery>)
    conn = get_conn()
    main()
