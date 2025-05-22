import json
import os
import mysql.connector as msql
from dotenv import load_dotenv
import logging

path = 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/ipl_json/2008-2020/'
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

team_names = {'Kolkata Knight Riders': 'KKR',
              'Sunrisers Hyderabad': 'SRH',
              'Deccan Chargers': 'SRH',
              'Royal Challengers Bangalore': 'RCB',
              'Chennai Super Kings': 'CSK',
              'Rajasthan Royals': 'RR',
              'Kings XI Punjab': 'KXIP',
              'Punjab Kings': 'KXIP',
              'Mumbai Indians': 'MI',
              'Delhi Daredevils': 'DC',
              'Delhi Capitals': 'DC',
              'Gujarat Lions': 'GL',
              'Kochi Tuskers Kerala': 'KTK',
              'Rising Pune Supergiants': 'RPS',
              'Rising Pune Supergiant': 'RPS',
              'Pune Warriors': 'RPS'}

def obtainMatches(date, team1, team2):
    # wont match for one case where date was changed so str_date is hardcoded 
    if date == "'2014-05-27'" and "'KKR'" in [team1, team2]: 
        date = "'2014-05-28'"
    match_sql = f"SELECT `match_id`, `inning`, `batsman`, `position`, `runs`, `balls`, `dismissal_type`, `bowler`, `fielder`, `runs_on_arrival`, `overs_on_arrival`, `runs_on_dismissal`, `overs_on_dismissal`, `end_partner_runs`, `end_partner_balls`, `dot_balls`, `singles`, `doubles`, `triples`, `fours`, `fives`, `sixes` from match_batsman_scorecards2 where match_id = (select match_id from matches where `date` = {date} and batting_team1 = {team1} and batting_team2 = {team2});"
    try:
        mycursor.execute(match_sql)
        scorecard = mycursor.fetchall()
        # checking whether number of matches is 1 only
        if not len(scorecard):
            logging.warning(f'No matches obtained for file- {file} and teams- {team1} {team2} date- {date}, checking for reverse')
            return None
        else: 
            for i in scorecard:
                if i[0] != scorecard[0][0]:
                    logging.critical(f"More than 1 match obtained {i[0]} {scorecard[0][0]} ")
                    return None
            else:
                logging.info(f'{scorecard[0][0]} obtained successfully for {file}')
                return scorecard
    except msql.Error as e:
        logging.critical(f"Match not obtained using date and teams -{str(e)}")
        return None

def updateMatchSquads(scorecard, team1, team2):
    teams = [team1, team2] 
    match_id = scorecard[0][0]
    insert_success_switch = 1
    for inn in range(1,3):
        batsmen = [list(entry) for entry in scorecard if entry[1] == inn] # existing batsmen rows in match_batsman_scorecards2 table 
        bat = [entry[2] for entry in scorecard if entry[1] == inn] # extracting batsmen names from the match_batsman_scorecards2 table
        logging.debug(f'Squad list for inning {inn} - {(", ").join(bat)}')
        for j,batsman in enumerate(batsmen):
            for k, key in enumerate(batsman):
                if type(key) is not str and key is not None:
                    batsmen[j][k] = str(key)
                elif key is None:
                    batsmen[j][k] = key
                else:
                    batsmen[j][k] = key.strip()
        count_batsman = max([entry[3] for entry in scorecard if entry[1] == inn]) if len(bat) else 0# number of batsmen who already reached the crease.
        # if len(bat) used, then retired hurt cases will cause issue (That too only when they come back to bat again)

        for batsman in teams[inn-1]:
            if batsman not in bat and count_batsman < 11:
                count_batsman += 1
                batsmen.append([str(match_id), str(inn), batsman, None, None,None,'DNB','DNB',None,None,None,None,None,None,None,None,None,None,None,None,None,None])
                bat.append(batsman)
                if len(batsmen) == 11 and len(bat) != 11:
                    print('Error somewhere') 
            elif count_batsman > 11:
                logging.error(f'More than 11 batsmen obtained {len(batsmen)} {batsman} {file}')

        # insert into new table with all 11 entries of a match in a sequence and updated dismissal and arrival overs
        match_sql = f"insert into `match_batsman_scorecards` (`match_id`, `inning`, `batsman`, `position`, `runs`, `balls`, `dismissal_type`, `bowler`, `fielder`, `runs_on_arrival`, `overs_on_arrival`, `runs_on_dismissal`, `overs_on_dismissal`, `end_partner_runs`, `end_partner_balls`, `dot_balls`, `singles`, `doubles`, `triples`, `fours`, `fives`, `sixes`) VALUES (%s, %s, %s, %s, %s,%s, %s,%s, %s, %s, %s,%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s);"
        try:
            mycursor.executemany(match_sql, batsmen)
            mydb.commit()
            logging.info(f'Batsmen inserted for inning {inn} and {match_id}')
        except msql.Error as e:
            insert_success_switch = 0
            logging.critical(f"Inning {inn} batsmen not added successfully and match_id- {match_id} {str(e)}")
    if insert_success_switch:
        logging.info(f'Finished for {match_id}\n')
    else:
        logging.critical(f'{match_id} skipped \n')

def checkInning1Score(team1_score,match_id):
    if team1_score:
        check_sql = f'select team1_runs from matches where match_id = {match_id};'
        mycursor.execute(check_sql)
        t1_score = mycursor.fetchall()
        logging.debug(f'{t1_score[0][0]} and {team1_score}')
        if t1_score[0][0] != team1_score and match_id not in dl_matches:
            #! team1_score has been acquired using Target, which wont match in cases of DuckWorth Lewis system being implemented
            logging.critical(f'{match_id} inning 1 scores do not match -{t1_score[0][0]} {team1_score} {file}')


replace_main = {
    'AS Yadav': 'Arjun Yadav',
    'R Bishnoi': 'Rajesh Bishnoi', 
    'N Saini': 'Nitin Saini', 
    'Navdeep Saini': 'NA Saini',
    'CV Varun': 'V Chakravarthy',
    'AD Hales': 'A Hales',
    'AJ Turner': 'A Turner',
    'AS Joseph': 'A Joseph',
    'AS Roy': 'A Roy',
    'CJ Dala': 'J Dala',
    'DJ Willey': 'D Willey',
    'DJM Short': 'D Short',
    'DR Shorey': 'D Shorey',
    'GC Viljoen': 'H Viljoen',
    'HF Gurney': 'H Gurney',
    'IS Sodhi': 'I Sodhi',
    'JL Denly': 'J Denly',
    'JP Behrendorff': 'J Behrendorff',
    'JPR Scantlebury-Searles': 'J Searles',
    'LE Plunkett': 'L Plunkett',
    'LS Livingstone': 'L Livingstone',
    'MA Wood': 'M Wood', 
    'NK Patel': 'Niraj Patel',
    'P Ray Barman': 'PR Barman',
    'RK Bhui': 'R Bhui',
    'Rasikh Salam':'R Salam',
    'SC Kuggeleijn': 'S Kuggeleijn',
    'SE Rutherford' : 'S Rutherford',
    'Y Prithvi Raj': 'P Raj'
}
mydb, mycursor = connectSQL()

dl_sql = f'select match_id from matches where result_type = "DL applied";'
mycursor.execute(dl_sql)
dl_matches = mycursor.fetchall()
dl_matches = [dl[0] for dl in dl_matches] 

i = 0
for file in os.listdir(path):

    with open(os.path.join(path,file), mode='r') as f:
        match = json.loads(f.read())
    try:
        team1_score = int(match['innings'][1]['target']['runs']) - 1
    except Exception as e:
        logging.warning(f'Team 1 score not obtained- {file} {str(e)}')
        team1_score = 0
    # Obtain player squads
    team1_squad = match['info']['players'][match['info']['teams'][0]]
    team2_squad = match['info']['players'][match['info']['teams'][1]]

    for x,pl1 in enumerate(team1_squad):
        if pl1 in replace_main.keys():
            team1_squad[x] = replace_main[pl1]
    for y, pl2 in enumerate(team2_squad):
        if pl2 in replace_main.keys():
            team2_squad[y] = replace_main[pl2]

    date = match['info']['dates'][0]
    teams = match['info']['teams']
    short_teams = list()
    for team in teams:
        try:
            short_teams.append(team_names[team])
        except Exception as e:
            logging.error(f'team name not obtained - {file} {date} {repr(team)} {str(e)} ')

    if len(short_teams) != 2:
        logging.critical(f"Error in getting teams' short name, skipping file - {file}")
        break
    
    # Match matches using date and teams
    str_date = '\'' + date+ '\''
    str_team1 = '\'' + short_teams[0] + '\''
    str_team2 = '\'' + short_teams[1] + '\''
    
    scorecard = obtainMatches(str_date, str_team1, str_team2)
    if not scorecard:
        # try with team2 as team1
        scorecard = obtainMatches(str_date, str_team2, str_team1)
        if not scorecard:
            logging.error(f'{file} skipped')
        else:
            logging.info('Going forward with order of teams changed')
            updateMatchSquads(scorecard, team2_squad, team1_squad)
            checkInning1Score(team1_score, scorecard[0][0])
    else:
        logging.info('Going forward with order of teams intact')
        updateMatchSquads(scorecard, team1_squad, team2_squad)
        checkInning1Score(team1_score, scorecard[0][0])
    i += 1
    print(f"{i} files completed")
