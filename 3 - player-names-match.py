import mysql.connector as msql
from dotenv import load_dotenv
import logging
import time
import os
log_path = 'D:/work/pythonPractice/big projects/IPL Analytics/work/py files'
logging.basicConfig(level=logging.ERROR, filename= log_path + '/app.log',format=f'%(levelname)s %(message)s')

def connectSQL():
    load_dotenv()
    HOST = os.getenv('HOST')
    PORT = os.getenv('PORT')
    USER = os.getenv('USER')
    PWD = os.getenv('PWD')
    DB = os.getenv('DB')
    mydb = msql.connect(
        host=HOST,
        port=PORT,
        user=USER,
        password=PWD,
        database=DB
    )
    mycursor = mydb.cursor()
    return mydb, mycursor


def obtainLists(i):
    pl_sql = f'select * from players where fullname is null limit 1 offset {i-1};'
    mycursor.execute(pl_sql)
    player = mycursor.fetchall()[0]
    # id, db_name, full_name, nation, role, bat_hand, bowl_hand, bowl_style;

    ps_sql = f'select batsman, season, team from player_seasons where batsman = "{player[1]}";'
    mycursor.execute(ps_sql)
    player_seasons = mycursor.fetchall()
    # batsman, season, team

    surname = (' ').join(player[1].split(' ')[1:])
    espn_sql = f'select * from espn_season_players where full_name like "%{surname}%" and status = 1;'
    mycursor.execute(espn_sql)
    espn_pl = mycursor.fetchall()
    # id, full_name, team, season, role, age, bat_hand, bowl_style

    sal_sql = f'select * from player_salaries where full_name like "%{surname}%" and status = 1;'
    mycursor.execute(sal_sql)
    sal_pl = mycursor.fetchall()
    # id, full_name, nation, role, salary, team, season

    return player, player_seasons, espn_pl, sal_pl


def findPlayerName(espn_pl, sal_pl):
    espn_names = list(set([pl[1].strip().title() for pl in espn_pl]))
    sal_names = list(set([pl[1].strip().title() + ' (s)' for pl in sal_pl if pl[1].strip().title() not in espn_names]))
    total_names = espn_names + sal_names
    print(f'\n--------------------------------------\nSelect a name from the above for player {player[1]}:')
    for u, name in enumerate(total_names):
        print(f'{u+1}. {name}')
    
    if len(total_names) == 1:
        time.sleep(1)
        return total_names[0]
    else:
        for i,name in enumerate(total_names):
            if name.title() == player[1]:
                single_name_case = input(f'Found a single, complete match: {total_names[i]}. Go ahead ?')
                time.sleep(1)
                if single_name_case.lower() == 'y':
                    return total_names[i]
                else:
                    return None
        else:
            inp = input(f'\nEnter choice: ')
        
        if inp.lower() == 'n':
            return None
        else:
            inp = int(inp)
            return total_names[inp-1]


def setPlayerRole(espn_entries, sal_entries):
    espn_roles = list(set([pl[4] for pl in espn_entries]))
    sal_roles = list(set([pl[3] for pl in sal_entries if pl[3] not in espn_roles]))
    roles = espn_roles + sal_roles
    print(roles)
    if len(roles) == 0:
        print(espn_entries, full_name)
        print(sal_entries, full_name)
    if len(roles) == 1:
        return roles[0]
    else: 
        rl_inp = int(input('Choose role to keep: '))
        return roles[rl_inp -1]


mydb, mycursor = connectSQL()

# obtain names from players, espn_season_players and season_players
for i in range(1,50):
    player, player_seasons, espn_pl, sal_pl = obtainLists(i)

    if sal_pl and espn_pl:
        full_name = findPlayerName(espn_pl, sal_pl)
        if full_name is None:
            continue
        
        if full_name.find('(C)') != -1:
            full_name = full_name[:-4]

        # ! IF SELECTED NAME WAS IN ESPN AND NOT IN SAL, BUT SOME SIMILAR NAMES EXIST IN SAL [WITH (S) TAG], THEN RENAME IT ELSE SALARY WONT MATCH
        
        # Setting players Role column
        espn_entries = [row for row in espn_pl if full_name in row[1].title()]
        sal_entries = [row for row in sal_pl if row[1].title() == full_name]

        role = setPlayerRole(espn_entries, sal_entries)
        
        # Bowling scene for players table
        try:
            bowl_style_split = espn_entries[0][7].split(' ')
            if 'right' in bowl_style_split or 'Right' in bowl_style_split:
                bowling_hand = 'Right'
            elif 'right' in bowl_style_split or 'Right' in bowl_style_split:
                bowling_hand = 'Left'
            else:
                bowling_hand = espn_entries[0][6]
        except Exception as e:
            time.sleep(5)
            print(str(e), espn_entries, player, full_name, full_name in espn_pl[0][1], espn_pl[0])
            continue
        bowl_style = espn_entries[0][7].title()

        # add the subsequent changes into the players table
        try:
            dl_sql = f'update players set fullname = "{full_name}", nation = "{sal_entries[0][2]}", player_role = "{role}", batting_hand = "{espn_entries[0][6]}", bowling_hand = "{bowling_hand}", bowling_style = "{bowl_style}" where player_id = {player[0]};'
            print(dl_sql)
            mycursor.execute(dl_sql)
            switch1 = 1
        except Exception as e:
            switch1 = 0
            print('Error while inserting', full_name, 'rows in players table-', str(e))

        season_rows = list()
        # for each row/ season in espn
        # check season/team combo from player_seasons

        espn_years = [(k[2],k[3]) for k in espn_entries]
        year_switch = 0
        for row in player_seasons:
            for l,row2 in enumerate(espn_years):
                if row[1] == row2[1] and row[2] == row2[0]:
                    espn_years.pop(l)
                    break
                elif row[1] == row2[1] and row[2] != row2[0]:
                    print(f'teams not matching',row[1],row2[1],row[2],row2[0])
                    espn_years.pop(l)
                    break
            else:
                print(f'year missing: {row[1]},{[year[3] for year in espn_entries]}')
                year_switch = 1
                # log
                time.sleep(5)
        if espn_years:
            print(f'Not played a single match in- {espn_years}, go ahead ? - ')
        if year_switch:
            continue
            
        if sal_entries:
            for r,row in enumerate(espn_entries):
                s_player = dict()
                s_player['player_id'] = str(player[0])

                s_player['team'] = row[2]
                
                s_player['season'] = str(row[3])

                if row[1].find('(c)') != -1:
                    s_player['role'] = 'Captain ' + row[4]
                else:
                    s_player['role'] = row[4]

                s_player['age'] = row[5]
                s_player['salary'] = '0'
                for sal_row in sal_entries:
                    # ! Match whether team and season matches with match_bowler_scorecards
                    if sal_row[5] == s_player['team'] and str(sal_row[6]) == s_player['season']:
                        s_player['salary'] = str(sal_row[4])
                        break
                if s_player['salary'] == '0':
                    print('Error in getting salaries, rename in salaries table', sal_row)

                if row[3] in [year[1] for year in espn_years]:
                    s_player['contribution'] = '0'
                else:
                    s_player['contribution'] = '1'

                season_rows.append(list(s_player.values()))
            print(season_rows)

            try:
                sp_sql = f'insert into season_players_info (player_id, team, season, player_role, age, salary, matches_played) VALUES (%s, %s, %s, %s, %s, %s, %s);'
                mycursor.executemany(sp_sql, season_rows)
                switch2 = 1
            except Exception as e:
                switch2 = 0
                print('Error while inserting',full_name,'season rows-' ,str(e))
            
            if switch1 and switch2:
                try:
                    status1_sql = f'update player_salaries set status = 0 where full_name = "{sal_entries[0][1]}";'
                    status2_sql = f'update espn_season_players set status = 0 where full_name like "%{full_name}%";'
                    print(status1_sql, status2_sql)
                    mycursor.execute(status1_sql)
                    mycursor.execute(status2_sql)
                    mydb.commit()
                    print('Players table successfully updated for', full_name)
                    print('Seasons rows table successfully updated for', full_name)
                except Exception as e:
                    time.sleep(3)
                    print("Final update and commit error", str(e))
        else:
            time.sleep(10)
            print(f'No salary entries for given full name {full_name} found - {sal_entries}')

    else:
        print('Missing values in salary or espn table', player)


# ! Players left after this name matching will be included in players even though they havent played any matches
