################### MAIN PLAYER TABLE (Players that were at least once in the Playing XI of a match) ####################
DROP Table IF EXISTS players;
CREATE TABLE IF NOT EXISTS players (
  player_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
  db_name VARCHAR(25) DEFAULT NULL,
  fullname VARCHAR(25) DEFAULT NULL,
  nation VARCHAR(25) DEFAULT NULL,
  player_role VARCHAR(25) DEFAULT NULL,
  batting_hand VARCHAR(5) DEFAULT NULL ,
  bowling_hand VARCHAR(5) DEFAULT NULL,
  bowling_style VARCHAR(40) NULL,
  PRIMARY KEY (player_id));

insert into players (db_name)  
select distinct batsman from match_batsman_scorecards;

################## "TEMP" PLAYER SALARIES AND ESPN SEASON SQUADS TABLE ###################
DROP TABLE IF EXISTS player_salaries;
CREATE TABLE IF NOT EXISTS player_salaries (
  season_player_id int unsigned NOT NULL AUTO_INCREMENT,
  full_name varchar(45) DEFAULT NULL,
  nation varchar(25) DEFAULT NULL,
  player_role VARCHAR(25) DEFAULT NULL,
  salary int DEFAULT NULL,
  team varchar(45) DEFAULT NULL,
  season year DEFAULT NULL,
  status int default 1,
  PRIMARY KEY (season_player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/player_salaries.csv' -- add your own path here
into table player_salaries 
fields terminated by ',' 
enclosed by '"' 
lines terminated by '\r\n' 
ignore 1 lines
(season_player_id, full_name,nation,player_role, @dummy, salary, team, season, @dummy);

DROP TABLE IF EXISTS espn_season_players;
CREATE TABLE IF NOT EXISTS espn_season_players (
  season_player_id int unsigned NOT NULL AUTO_INCREMENT,
  full_name varchar(45) DEFAULT NULL,
  team varchar(45) DEFAULT NULL,
  season year DEFAULT NULL,
  player_role VARCHAR(35) DEFAULT NULL,
  age VARCHAR(25) DEFAULT NULL,
  batting_hand VARCHAR(105) DEFAULT NULL,
  bowling_style VARCHAR(105) DEFAULT NULL,
  status int default 1,
  PRIMARY KEY (season_player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/squad_list_espn.csv' -- add your own path here
into table espn_season_players
fields terminated by ',' 
enclosed by '"' 
lines terminated by '\n' 
ignore 1 lines;

update player_salaries p join no_matches_played n on n.fullname = p.full_name and n.season = p.season set status = 0;
update espn_season_players p join no_matches_played n on n.fullname = p.full_name and n.season = p.season set status = 0;

-- checking number of players in each team for each squad in each table
select team, season, t1.squad, t2.squad, t1.squad - t2.squad from (select team, season, count(*) squad from espn_season_players group by team, season) t1 join (select team, season, count(*) squad from player_salaries group by team, season) t2 using (team, season) where (t1.squad - t2.squad) != 0 ;

################## "TEMP" SEASON SQUADS TABLE (seasons in which each player was in the playing XI for at least one instance)###################
drop table if exists player_seasons;
create table if not EXISTS player_seasons 
with cte1 as
(select match_id, year(date) season, result_type, batsman, batting_team1 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, non_striker, batting_team1 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, bowler, batting_team1 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, fielder, batting_team1 from deliveries d join matches m using (match_id) where inning = 2 and fielder is not null and fielder not like '%(sub)%'), cte2 as
(select match_id, year(date) season, result_type, batsman, batting_team2 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, non_striker, batting_team2 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, bowler, batting_team2 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, fielder, batting_team2 from deliveries d join matches m using (match_id) where inning = 1  and fielder is not null and fielder not like '%(sub)%')
select season, batsman, batting_team1 from (select season, batting_team1, batsman from cte1 union select season, batting_team2, batsman from cte2 ) as t order by batsman, season;

alter table player_seasons add column player_season_id int UNSIGNED NOT NULL AUTO_INCREMENT first, ADD PRIMARY KEY(player_season_id), rename COLUMN batting_team1 to team, add COLUMN contribution smallint DEFAULT 2;

-- players that had ZERO CONTRIBUTION in any match in any season THEY PLAYED (no balls bowled/ faced, no fielding contributions)
insert into player_seasons (season, batsman, team, contribution)
with cte as (select distinct season, batting_team1, batsman from (select match_id, year(date) season, batting_team1, batsman from match_batsman_scorecards JOIN matches USING (match_id) where inning = 1 union select match_id, year(date) season, batting_team2, batsman from match_batsman_scorecards JOIN matches USING (match_id) where inning = 2) t) 
SELECT cte.season, cte.batsman, cte.batting_team1, 1 from cte left join player_seasons p on p.batsman = cte.batsman AND p.season = cte.season where p.batsman is null;

select * from player_seasons where player_season_id not in (select player_season_id from player_seasons ps join players p on ps.batsman = p.db_name join season_players_info sp on sp.fullname = p.fullname and sp.season = ps.season);

-- These 2 should be equal
select * from season_players_info where matches_played = 1;
select * from player_seasons;

################## FINAL SEASON SQUADS WITH SALARY TABLE ###################

DROP TABLE IF EXISTS season_players_info ;
CREATE TABLE IF NOT EXISTS season_players_info (
  season_player_id int unsigned NOT NULL AUTO_INCREMENT,
  player_id int DEFAULT NULL,
  fullname varchar(45) DEFAULT NULL,
  team varchar(5) DEFAULT NULL,
  season year DEFAULT NULL,
  player_role VARCHAR(35) DEFAULT NULL,
  age VARCHAR(25) DEFAULT NULL,
  salary int DEFAULT NULL,
  matches_played smallint DEFAULT NULL,
  PRIMARY KEY (season_player_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

#################################################################
-- PYTHON SCRIPT FOR VERIFYING NAMES, TEAMS, SEASONS AND SALARIES
#################################################################

alter table season_players_info add column fullname VARCHAR(25) DEFAULT NULL after player_id;
update season_players_info s join players p using (player_id) set s.fullname = p.fullname ;

-- change batsman to opener/ top order/ middle order
-- change bowler to spinner/ seamer/ pacer
-- regular starter or not 

-- Players that didnt play a single match but got drafted in the auction
DROP TABLE IF EXISTS no_matches_played ;
CREATE TABLE IF NOT EXISTS no_matches_played (
  id int unsigned NOT NULL AUTO_INCREMENT,
  fullname varchar(45) DEFAULT NULL,
  team varchar(45) DEFAULT NULL,
  season year DEFAULT NULL,
  player_role VARCHAR(35) DEFAULT NULL,
  age VARCHAR(25) DEFAULT NULL,
  salary int DEFAULT 0,
  batting_hand VARCHAR(5) DEFAULT NULL ,
  bowling_style VARCHAR(40) NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

insert into no_matches_played (fullname, team, season, player_role, age, salary, batting_hand, bowling_style)
select full_name, p.team, season, e.player_role, age, salary, batting_hand, bowling_style from player_salaries p join espn_season_players e using(full_name, season) where p.status =1 and e.status = 1;

update no_matches_played set bowling_style = null where bowling_style = '';
update players set bowling_style = null where bowling_style = '';

alter table players add column bowling_type varchar(15) default null after bowling_hand;
update players set bowling_type = (case when bowling_style like '%fast' then 'Pacer' 
									   when bowling_style like '%Arm Medium' then 'Medium Pacer' 
									   when bowling_style is not null then 'Spinner' 
                                       else null end);

update season_players_info s1 join (select season_player_id, p.player_id, p.db_name, year(b.date) season, count(*) match_played from season_players_info s join players p using (player_id) join (select * from match_batsman_scorecards join matches using (match_id)) b on b.batsman = p.db_name and year(b.date) = s.season group by batsman, season) s2 using (season_player_id) set matches_played = match_played;

DROP TABLE IF EXISTS player_salaries;
DROP TABLE IF EXISTS espn_season_players;
DROP TABLE IF EXISTS player_seasons;