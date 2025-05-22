import mysql.connector as msql
from dotenv import load_dotenv
import os
import logging
import time
import pandas as pd

class Ball():
    def __init__(self,ball):
        self.ball_id = ball[0]
        self.match_id = ball[1]
        self.inning = ball[2]
        self.over = ball[3]
        self.ball = ball[4]
        self.batsman = ball[5].strip()
        self.non_striker = ball[6].strip()
        self.bowler = ball[7].strip()
        self.noball_runs = ball[8]
        self.batsman_runs = ball[9]
        self.extra_runs = ball[10]
        self.total_runs = ball[11]
        self.extra_type = ball[12] if ball[12] else ''
        self.player_dismissed = ball[13] if ball[13] else ''
        self.dismissal_kind = ball[14] if ball[14] else ''
        self.fielder = ball[15].strip() if ball[15] else ''
        self.batsmen = (ball[5],ball[6])
    
def updateDeliveries(startID, endID):

    db_sql = f"SELECT * from deliveries where match_id between {startID} and {endID} order by match_id, inning, `over`, ball;"
    try:
        mycursor.execute(db_sql)
        balls = mycursor.fetchall()
    except msql.Error as e:
        logging.exception("Exception occurred")

    miCombo = [0, 0]
    teamRuns = 0
    teamOvers = 0.0
    teamWickets = 0
    batsmen = [{
        'id': 1,
        'runs': 0,
        'balls': 0,
        'name':'-'
    },{
        'id': 2,
        'runs': 0,
        'balls': 0,
        'name':'-'
    }] 
    

    def checkWickets(cBall, nBall,batsman):
        if not cBall.player_dismissed:  # player_dismissed is null
            if (nBall.match_id != cBall.match_id) or (nBall.inning != cBall.inning):
                pass
            else:
                logging.warning(f'player dismissal not recorded for {cBall.ball_id}')
        nonlocal teamWickets, wicket_string
        if cBall.dismissal_kind != 'retired hurt':
            teamWickets += 1
        wicket_string = ' || W ' + batsman['name'] + ' (' + str(batsman['runs']) + ','+str(batsman['balls'])+') ' + cBall.dismissal_kind + ' ' + cBall.fielder + 'b ' + cBall.bowler
        other_batsman = [bat for bat in batsmen if batsman['id'] != bat['id']] # the one who stays i.e. whose values wont change
        if other_batsman[0]['name'] == nBall.batsman and int((teamOvers*10)%10) != 0:
            batsman['name'] = nBall.non_striker
        elif other_batsman[0]['name'] == nBall.batsman and int((teamOvers*10)%10) == 0:
            batsman['name'] = nBall.non_striker
        elif other_batsman[0]['name'] == nBall.non_striker and int((teamOvers*10) % 10) != 0:
            batsman['name'] = nBall.batsman
        else:
            batsman['name'] = nBall.batsman
        batsman['runs'] = 0
        batsman['balls'] = 0
        if teamWickets == 10:
            batsman['name'] = None
            batsman['runs'] = 0
            batsman['balls'] = 0
        
    for i in range(len(balls)-1):
        
        wicket_string, bye_string, legbye_string = '', '', ''
        cBall = Ball(balls[i])
        nBall = Ball(balls[i+1])
        
        # Checking for innings change
        if miCombo != [cBall.match_id, cBall.inning]:
            miCombo = [cBall.match_id, cBall.inning]
            logging.info(f'miCombo changed at ballID - {cBall.ball_id} with {miCombo}')
            for bat in batsmen:
                bat['runs'] = 0
                bat['balls'] = 0
            teamRuns, teamOvers, teamWickets, batsmen[0]['name'], batsmen[1]['name'] = 0, 0.0, 0, cBall.batsman, cBall.non_striker
        
        if batsmen[0]['name'] == batsmen[1]['name']:
            logging.error(f'Both batsmen same at {teamOvers} ')
            break

        # Changing batsman on strike
        if cBall.batsman != batsmen[0]['name']:
            for key in batsmen[0]:
                batsmen[0][key], batsmen[1][key] = batsmen[1][key], batsmen[0][key]

        teamRuns += cBall.total_runs
        batsmen[0]['runs'] += cBall.batsman_runs

        # checking for legal deliveries
        if cBall.extra_type != 'wides' and cBall.noball_runs == 0 and cBall.extra_type != 'wides (p)':

            # Updating teamOvers and checking for over change
            if int(str(teamOvers)[-1]) > 5:
                logging.error(f'Ball skipped or added somewhere {cBall.ball_id} ')
                break
            elif str(teamOvers)[-1] == '5':
                teamOvers += 0.5
            else:
                teamOvers += 0.1
            teamOvers = round(teamOvers, 1)
            batsmen[0]['balls'] += 1

            if (cBall.batsman not in nBall.batsmen):
                checkWickets(cBall,nBall,batsmen[0])
                
            elif (cBall.non_striker not in nBall.batsmen):
                checkWickets(cBall, nBall, batsmen[1])

            if cBall.extra_type == 'legbyes' :
                legbye_string = ' Legbyes ' + str(cBall.extra_runs)
            elif cBall.extra_type == 'byes':
                bye_string = ' Byes ' + str(cBall.extra_runs)
            ball_string = f"{cBall.match_id}|{cBall.inning} - {cBall.ball_id} :- {teamRuns}/{teamWickets}  {teamOvers} ||{batsmen[0]['name']} ({batsmen[0]['runs']},{batsmen[0]['balls']}) | {batsmen[1]['name']} ({batsmen[1]['runs']},{batsmen[1]['balls']})|| {cBall.total_runs}"
            logging.debug(ball_string + bye_string + legbye_string + wicket_string)

        else: 
            if (cBall.batsman not in nBall.batsmen) and (nBall.inning == cBall.inning):
                checkWickets(cBall, nBall,batsmen[0])

            elif (cBall.non_striker not in nBall.batsmen):
                checkWickets(cBall, nBall,batsmen[1])
            ball_string = f"{cBall.match_id}|{cBall.inning} - {cBall.ball_id} :- {teamRuns}/{teamWickets}  {teamOvers} ||{batsmen[0]['name']} ({batsmen[0]['runs']},{batsmen[0]['balls']}) | {batsmen[1]['name']} ({batsmen[1]['runs']},{batsmen[1]['balls']})  || {cBall.total_runs} Extras - {cBall.extra_runs}"

            if cBall.extra_type == 'legbyes':
                legbye_string = ' Legbyes ' + str(cBall.extra_runs)
            elif cBall.extra_type == 'byes':
                bye_string = ' Byes ' + str(cBall.extra_runs)
            logging.debug(ball_string + bye_string + legbye_string + wicket_string)
        
        balls[i] = list(vars(cBall).values())[:16]
        balls[i].extend([batsmen[0]['runs'], batsmen[0]['balls'],batsmen[1]['runs'],batsmen[1]['balls'],teamRuns,teamOvers])

    last_ball = Ball(balls[len(balls)-1])
    # swap batsmen according to matching names
    if last_ball.batsman != batsmen[0]['name']:
        for key in batsmen[0]:
            batsmen[0][key], batsmen[1][key] = batsmen[1][key], batsmen[0][key]
    teamRuns += last_ball.total_runs
    batsmen[0]['runs'] += last_ball.batsman_runs
    if last_ball.player_dismissed and last_ball.player_dismissed != 'retired hurt':
        teamWickets += 1
    if cBall.extra_type != 'wides' and cBall.noball_runs == 0 and cBall.extra_type != 'wides (p)':
        if str(teamOvers)[-1] == '5':
            teamOvers += 0.5
        else:
            teamOvers += 0.1
        teamOvers = round(teamOvers, 1)
        batsmen[0]['balls'] += 1
    ball_string = f"{last_ball.match_id}|{last_ball.inning} - {last_ball.ball_id} :- {teamRuns}/{teamWickets}  {teamOvers} ||{batsmen[0]['name']} ({batsmen[0]['runs']},{batsmen[0]['balls']}) | {batsmen[1]['name']} ({batsmen[1]['runs']},{batsmen[1]['balls']})  || {cBall.total_runs} Extras - {cBall.extra_runs}"
    logging.debug(ball_string + bye_string + legbye_string + wicket_string)

    balls[len(balls)-1] = list(vars(last_ball).values())[:16]
    balls[len(balls)-1].extend([batsmen[0]['runs'], batsmen[0]['balls'],batsmen[1]['runs'],batsmen[1]['balls'],teamRuns,teamOvers])

    return balls

replace_names = {
    'T Curran' : 'TK Curran',
    'M Lomror': 'MK Lomror',
    'AS Yadav': 'SA Yadav',
    'K Ahmed': 'KK Ahmed',
    'C Ingram':'CA Ingram',
    'P Shaw':'PP Shaw',
    'K Paul':'KMA Paul',
    'S Gill':'Shubman Gill',
    'M Ur Rahman': 'Mujeeb Ur Rahman',
    'S Curran':'SM Curran',
    'R Bishnoi':'Rajesh Bishnoi',
    'H Brar':'Harpreet Brar',
    'W Saha':'WP Saha',
    'S Warrier': 'S Sandeep Warrier',
    'M Santner': 'MJ Santner',
    'S Mavi': 'Shivam Mavi',
    'L Ferguson':'LH Ferguson',
    'M Ali':'MM Ali',
    'S Hetmyer':'SO Hetmyer',
    'N Saini': 'NA Saini',
    'J Archer': 'JC Archer',
    'J Bairstow': 'JM Bairstow',
    'N Naik': 'NS Naik',
    'S Sharma': 'Sandeep Sharma',
    'S Singh': 'P Simran Singh',
    'P Krishna': 'M Prasidh Krishna',
    'CV Varun': 'V Chakravarthy',
    'R Singh': 'RK Singh',
    'H Vihari': 'GH Vihari'
}

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

# To view ball by ball data, set level = logging.DEBUG
logging.basicConfig(level=logging.ERROR, filename='app2.log',format=f'%(levelname)s %(message)s')

data = list()
cols = ['ball_id','match_id','inning','over','ball','batsman','non_striker','bowler','noball_runs','batsman_runs','extra_runs','total_runs', 'extra_type','player_dismissed','dismissal_kind','fielder', 'striker_runs','striker_balls','non_striker_runs','non_striker_balls', 'team_runs','team_overs']
# running in steps just so that my laptop survives this operation :)
for step in range(9):
    balls = updateDeliveries(step*100 +1, (step+1)*100)
    if balls:
        data.extend(balls)
        logging.debug(f'Taking a 3 second break, going for {step+2}th range,completed range from {step*100 +1} to {(step+1)*100}')
        print(f'Taking a 5 second break, going for {step+2}th range, completed range from {step*100 +1} to {(step+1)*100}')
        time.sleep(3)
    else: 
        logging.error('Error in data generation. Final array not compiled properly')

print('Data generation complete. Proceeding to create csv file ')
time.sleep(2)

for i,ball in enumerate(data):
    if ball[5] in list(replace_names.keys()):
        logging.warning(f'{data[i][5]} values changed for batsman column')
        data[i][5] = replace_names[ball[5]]
    if ball[6] in list(replace_names.keys()):
        logging.warning(f'{data[i][6]} values changed for non-striker column')
        data[i][6] = replace_names[ball[6]]
    if ball[7] in list(replace_names.keys()):
        logging.warning(f'{data[i][7]} values changed for bowler column')
        data[i][7] = replace_names[ball[7]]
    if ball[13] in list(replace_names.keys()):
        logging.warning(f'{data[i][13]} values changed for player dismissed column')
        data[i][13] = replace_names[ball[13]]
    if ball[15] in list(replace_names.keys()):
        logging.warning(f'{data[i][15]} values changed for fielder column')
        data[i][15] = replace_names[ball[15]]
  
print('Changed names')
time.sleep(2)
df = pd.DataFrame(data, columns=cols)
df.to_csv('f-deliveries.csv', index= False)
print('Done')
