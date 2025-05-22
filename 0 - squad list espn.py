from selenium import webdriver
driver = webdriver.Firefox(executable_path='C:\\Program Files\\Mozilla Firefox\\geckodriver-v0.29.0-win64\\geckodriver.exe')
import json
import time
import pandas as pd
# https://www.sportskeeda.com/cricket/ipl-teams-and-squads

season_obj = {
    '2019': '1165643',
    '2018': '1131611',
    '2020': '1210595',
    '2017': '1078425',
    '2016': '968923',
    '2015': '791129',
    '2014': '695871',
    '2013': '586733',
    '2012': '520932',
    '2011': '466304',
    '2010': '418064',
    '2009': '374163',
    '2008': '313494',
}

def getSeasonSquadLinks(year,s_link):
    driver.get(f'https://www.espncricinfo.com/ci/content/squad/index.html?object={s_link}')
    time.sleep(2)
    try:
        squads_link = driver.find_element_by_class_name('squads_list').find_elements_by_tag_name('li')
        season_squad_links = [link.find_element_by_tag_name('a').get_attribute("href") for link in squads_link]
        print(f'{year} completed')
        output = {'year': year, 'links':season_squad_links}
        return output        
    except Exception as e:
        print("BT",year, str(e))
        return None

def scrapESPN(sq_links, season):
    try:
        driver.get(sq_links)
        time.sleep(2)
        try:
            squad_name = (' ').join(driver.find_element_by_tag_name('h1').text.split(' ')[:-1])
        except Exception as e:
            print("Team name not obtained", str(e), sq_links)
            squad_name = ''
        squad_details = driver.find_elements_by_class_name('squad-player-content')
        players = []
        for squad in squad_details:
            player = {}
            player['name'] = squad.find_element_by_class_name('player-page-name').text
            player['team'] = squad_name
            player['season'] = season
            try:
                player['position'] = squad.find_element_by_class_name('playing-role').text
                player['age'] = squad.find_element_by_class_name('meta-info').text
                if len(squad.find_elements_by_class_name('meta-info')) == 2:
                    player['batting_hand'] = squad.find_elements_by_class_name('meta-info')[1].find_element_by_tag_name('div').text
                    if len(squad.find_elements_by_class_name('meta-info')[1].find_elements_by_tag_name('div')) ==2 :
                        player['bowling_hand'] = squad.find_elements_by_class_name('meta-info')[1].find_elements_by_tag_name('div')[1].text
                players.append(player)
            except Exception as e:
                print("Error in finding player-", str(e),player['name'], sq_links)
        return players
    except Exception as e:
        print("Error in finding squad players-", str(e), sq_links)
        return None

main_links = list()
for year, obj in season_obj.items():
    res = getSeasonSquadLinks(year, obj)
    if res:
        main_links.append(res)

output = []
for year in main_links[2:]:
    for link in year['links']:
        res = scrapESPN(link, year['year'])
        if res:
            output.extend(res)
            print(year['year'], link, 'complete')
        else:
            print(year['year'], link, 'failed')

cols = ['name','team','season','position','age','batting_hand', 'bowling_hand']
df = pd.DataFrame(data=output, columns= cols)
df.to_csv('squad_list_espn.csv', index= False)