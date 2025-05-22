#################### IMPORTING BASE TABLES ####################
use ipl;
drop table if exists matches;
drop table if exists teams;
drop table if exists venues;
drop table if exists deliveries;
drop table if exists super_over_balls;

CREATE TABLE if not exists matches (
  match_id int unsigned NOT NULL ,
  season MEDIUMINT NOT NULL,
  city varchar(30) DEFAULT NULL,
  `date` text NOT NULL,
  batting_team1 varchar(30) NOT NULL,
  batting_team2 varchar(30) NOT NULL,
  toss_winner varchar(30) DEFAULT 'NR',
  toss_decision varchar(30) DEFAULT 'NR',
  result_type varchar(10) DEFAULT 'no result',
  dl_applied SMALLINT DEFAULT 0,
  winner varchar(30) DEFAULT 'NR',
  win_by_runs SMALLINT DEFAULT 0,
  win_by_wickets SMALLINT DEFAULT 0,
  player_of_match varchar(30) DEFAULT 'NR',
  venue varchar(60) NOT NULL,
  PRIMARY KEY (match_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/matches.csv' -- add your own path here
into table matches
fields terminated by ','
enclosed by '"' lines
terminated by '\n'
ignore 1 lines;

insert into matches (match_id, season, city, date, batting_team1, batting_team2, venue) 
VALUES (701, 2008, 'Delhi', '2008-05-22', 'Delhi Daredevils', 'Kolkata Knight Riders', 'Feroz Shah Kotla Ground'),
		(702, 2009, 'Durban', '2009-04-21', 'Mumbai Indians', 'Rajasthan Royals', 'Kingsmead'),
        (703, 2009, 'Cape Town', '2009-04-25', 'Chennai Super Kings', 'Kolkata Knight Riders', 'Newlands'),
        (704, 2011, 'Bengaluru', '2011-04-19', 'Royal Challengers Bangalore', 'Rajasthan Royals', 'M Chinnaswamy Stadium'),
        (705, 2012, 'Kolkata', '2012-04-24', 'Deccan Chargers', 'Kolkata Knight Riders', 'Eden Gardens'),
        (706, 2012, 'Bengaluru', '2012-04-25', 'Chennai Super Kings', 'Royal Challengers Bangalore', 'M Chinnaswamy Stadium'),
        (707, 2015, 'Kolkata', '2015-04-26', 'Rajasthan Royals', 'Kolkata Knight Riders', 'Eden Gardens'),
        (708, 2017, 'Bengaluru', '2017-04-25', 'Royal Challengers Bangalore', 'Sunrisers Hyderabad', 'M Chinnaswamy Stadium');

CREATE TABLE if not exists deliveries (
  ball_id int unsigned NOT NULL AUTO_INCREMENT,
  match_id int unsigned NOT NULL,
  inning int DEFAULT NULL,
  batting_team varchar(30) NOT NULL,
  bowling_team varchar(30) NOT NULL,
  `over` smallint NOT NULL,
  ball smallint NOT NULL,
  batsman varchar(30) NOT NULL,
  non_striker varchar(30) NOT NULL,
  bowler varchar(30) NOT NULL,
  is_super_over smallint DEFAULT 0,
  wide_runs int DEFAULT NULL,
  bye_runs int DEFAULT NULL,
  legbye_runs int DEFAULT 0,
  noball_runs int DEFAULT 0,
  penalty_runs int DEFAULT 0,
  batsman_runs int DEFAULT 0,
  extra_runs int DEFAULT 0,
  total_runs int DEFAULT 0,
  player_dismissed varchar(30) DEFAULT NULL,
  dismissal_kind varchar(30) DEFAULT NULL,
  fielder varchar(30) DEFAULT NULL,
  PRIMARY KEY (ball_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/deliveries.csv'  -- add your own path here
into table deliveries
fields terminated by ','
enclosed by '"' lines
terminated by '\n'
ignore 1 lines;

#################### MATCH ID VALUES REFORMATTED ####################
-- No window function used as the match_ids need to be updated in both the tables
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id + 800 where m.season = 2017;
update matches set match_id = match_id + 800 where season = 2017 and match_id != 708;
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 59 where m.season < 2017;
update matches set match_id = match_id -59 where season < 2017 and match_id not between 701 and 707;
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 223 where m.season = 2017;
update matches set match_id = match_id - 223 where season = 2017 and match_id != 708;
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 7185 where m.season = 2018;
update matches set match_id = match_id - 7185 where season = 2018;
update matches set `date` = str_to_date(`date`, '%d/%m/%Y') where season in (2018,2019);
alter table matches modify column `date` DATE;
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 10368 where m.season = 2019 and m.date <'2019-04-06';
update matches set match_id = match_id - 10368 where season = 2019 and `date` <'2019-04-06';
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 10523 where m.season = 2019 and m.`date` > '2019-04-05' and m.match_id not in (11415,11414,11413,11412);
update matches set match_id = match_id - 10523 where season = 2019 and `date` > '2019-04-05' and match_id not in (11415,11414,11413,11412);
update deliveries d join matches m on d.match_id = m.match_id set d.match_id = d.match_id - 10587 where m.match_id in (11415,11414,11413,11412);
update matches set match_id = match_id - 10587 where match_id in (11415,11414,11413,11412);

#################### REFORMATTING MATCHES BASE TABLE TO MAKE IT COHERENT WITH THE NEW_MATCHES DATASET ####################
alter table matches add column win_type varchar(10) default null after winner, add column win_margin smallint default null after win_type;
update matches set win_type = 'runs', win_margin = win_by_runs where win_by_runs > 0;
update matches set win_type = 'wickets', win_margin = win_by_wickets where win_by_wickets > 0;
update matches set win_type = 'super over', win_margin = 0 where result_type = 'tie';
alter table matches drop column season, drop column win_by_runs, drop column win_by_wickets;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/new_matches2020.csv' -- add your own path here
into table matches
fields terminated by ','
enclosed by '"' lines
terminated by '\n'
ignore 1 lines;

#################### RENAMING SOME VALUES TO AVOID DIFFERENT NAMES FOR THE SAME FIELD VALUE ####################
update matches set date = '2014-05-28' where match_id = 455;        
update matches set city = 'Dubai' where city = '';
update matches set city = 'Bengaluru' where city = 'Bangalore';
update matches set city = 'Chandigarh' where city = 'Mohali';
update matches set venue = 'M Chinnaswamy Stadium' where venue = 'M. Chinnaswamy Stadium';
update matches set venue = 'Sheikh Zayed Stadium' where venue = 'Sheikh Zayed Stadium\r';
update matches set venue = 'Sharjah Cricket Stadium' where venue = 'Sharjah Cricket Stadium\r';
update matches set venue = 'Dubai International Cricket Stadium' where venue = 'Dubai International Cricket Stadium\r';
update matches set venue = 'MA Chidambaram Stadium, Chepauk' where venue = 'M. A. Chidambaram Stadium';
update matches set venue = 'Punjab Cricket Association Stadium, Mohali' where venue = 'Punjab Cricket Association IS Bindra Stadium, Mohali';
update matches set venue = 'Punjab Cricket Association Stadium, Mohali' where venue = 'IS Bindra Stadium';
update matches set venue = 'Feroz Shah Kotla Ground' where venue = 'Feroz Shah Kotla';
update matches set venue = 'Rajiv Gandhi Intl. Cricket Stadium' where venue = 'Rajiv Gandhi International Stadium, Uppal';
update matches set venue = 'ACA-VDCA Stadium' where venue = 'Dr. Y.S. Rajasekhara Reddy ACA-VDCA Cricket Stadium';
update matches set batting_team1 = 'Rising Pune Supergiants' where batting_team1 = 'Rising Pune Supergiant';
update matches set batting_team2 = 'Rising Pune Supergiants' where batting_team2 = 'Rising Pune Supergiant';
update matches set winner = 'Rising Pune Supergiants' where winner = 'Rising Pune Supergiant';
update matches set toss_winner = 'Rising Pune Supergiants' where toss_winner = 'Rising Pune Supergiant';
update matches set result_type = 'DL applied' where  dl_applied = 1;
update matches set winner = 'NR' where winner = '';
update matches set player_of_match = 'NR' where player_of_match = '';
update deliveries set batting_team = 'Rising Pune Supergiants' where batting_team = 'Rising Pune Supergiant';
update deliveries set bowling_team = 'Rising Pune Supergiants' where bowling_team = 'Rising Pune Supergiant';

#################### VENUES AND TEAMS TABLE ####################
CREATE TABLE if not exists venues (
  venue_id int unsigned NOT NULL AUTO_INCREMENT,
  stadium varchar(100) DEFAULT NULL,
  city varchar(45) DEFAULT NULL,
  nation varchar(45) DEFAULT 'India',
  PRIMARY KEY (venue_id)
) ENGINE=InnoDB AUTO_INCREMENT=64 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert into venues (city, stadium)
select distinct city, venue from matches;
update venues set nation = 'UAE' WHERE city in ('Sharjah', 'Abu Dhabi', 'Dubai');
update venues set nation = 'South Africa' WHERE city in (select DISTINCT city from matches where year(date) = 2009);
-- get stadium stats from sportsf1.com

CREATE TABLE IF NOT EXISTS teams (
  team_id SMALLINT unsigned NOT NULL AUTO_INCREMENT,
  team_name varchar(45) DEFAULT NULL,
  status tinyint DEFAULT '1',
  parent_team_id int DEFAULT NULL,
  team_short_name varchar(5) DEFAULT NULL,
  home_stadium1 smallint DEFAULT NULL,
  home_stadium2 smallint DEFAULT NULL,
  PRIMARY KEY (team_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
insert into teams (team_name)
select distinct batting_team1 from matches;

UPDATE teams SET parent_team_id = '11', team_short_name = 'SRH', home_stadium1 = 70, home_stadium2 = 88 WHERE (team_id = '11');
UPDATE teams SET parent_team_id = '4', team_short_name = 'MI', home_stadium1 = 67, home_stadium2 = 72 WHERE (team_id = '4');
UPDATE teams SET parent_team_id = '13', team_short_name = 'GL', home_stadium1 = 96, home_stadium2 = 97, status = 0 WHERE (team_id = '13');
UPDATE teams SET parent_team_id = '12', team_short_name = 'RPS', home_stadium1 = 89, home_stadium2 = 95, status = 0 WHERE (team_id = '12');
UPDATE teams SET parent_team_id = '7', team_short_name = 'RCB', home_stadium1 = 64 WHERE (team_id = '7');
UPDATE teams SET parent_team_id = '1', team_short_name = 'KKR', home_stadium1 = 68 WHERE (team_id = '1');
UPDATE teams SET parent_team_id = '6', team_short_name = 'KXIP', home_stadium1 = 65, home_stadium2 = 85 WHERE (team_id = '6');
UPDATE teams SET parent_team_id = '2', team_short_name = 'CSK', home_stadium1 = 71, home_stadium2 = 91 WHERE (team_id = '2');
UPDATE teams SET parent_team_id = '3', team_short_name = 'RR', home_stadium1 = 69, home_stadium2 = 82 WHERE (team_id = '3');
UPDATE teams SET parent_team_id = '11', team_short_name = 'SRH', home_stadium1 = 70, home_stadium2 = 88, status = 0 WHERE (team_id = '5');
UPDATE teams SET parent_team_id = '9', team_short_name = 'KTK', home_stadium1 = 86, home_stadium2 = 87, status = 0 WHERE (team_id = '9');
UPDATE teams SET parent_team_id = '12', team_short_name = 'RPS', home_stadium1 = 89, home_stadium2 = 95, status = 0 WHERE (team_id = '10');
UPDATE teams SET parent_team_id = '14', team_short_name = 'DC', home_stadium1 = 66, home_stadium2 = 90 WHERE (team_id = '14');
UPDATE teams SET parent_team_id = '14', team_short_name = 'DC', home_stadium1 = 66, home_stadium2 = 90, status = 0 WHERE (team_id = '8');

#################### USING THE VENUES AND TEAMS TABLE TO REFORMAT MATCHES AND DELIVERIES TABLE ####################
-- team1 = batting first team always. Thus, team1 column from matches.csv renamed to batting_team1. Also, if toss_winner = team1, then toss_decision = bat. However, if toss_winner = team2, then toss_decision = field.
alter table matches add column venue_id smallint default null after city;
update matches as m, venues as v set m.venue_id= v.venue_id where m.city = v.city and m.venue= v.stadium;
alter table matches drop column dl_applied, drop column city, drop COLUMN venue, drop column toss_decision;

update matches set batting_team2 = (select team_short_name from teams where matches.batting_team2 = teams.team_name);
update matches set batting_team1 = (select team_short_name from teams where matches.batting_team1 = teams.team_name);
update matches set toss_winner = (select team_short_name from teams where matches.toss_winner = teams.team_name) where toss_winner != 'NR';
update matches set winner = (select team_short_name from teams where matches.winner = teams.team_name) where winner != 'NR';

#################### SUPER OVERS TABLE AND ITS DATA VALIDATION/ INSERTION ####################
update deliveries set is_super_over = 1 where inning > 2 and is_super_over = 0;
update deliveries set inning = 4 where inning = 5;
insert into deliveries (match_id, inning, batting_team, bowling_team, `over`, ball, batsman, non_striker, bowler, is_super_over, wide_runs, bye_runs, legbye_runs, noball_runs, penalty_runs, batsman_runs, extra_runs, total_runs, player_dismissed, dismissal_kind, fielder) values 
		(778,3,'Delhi Capitals','Kolkata Knight Riders',1,3,'SS Iyer','RR Pant','P Krishna',1,0,0,0,0,0,0,0,0,'SS Iyer','caught','PP Chawla'),
		(778,4,'Kolkata Knight Riders', 'Delhi Capitals',1,3,'AD Russell','KD Karthik','K Rabada',1,0,0,0,0,0,0,0,0,'AD Russell', 'bowled',''),
		(819,3,'Sunrisers Hyderabad','Mumbai Indians',1,1,'MK Pandey','Mohammad Nabi','JJ Bumrah',1,0,0,0,0,0,1,0,1,'MK Pandey','run out','KH Pandya'),
		(819,3,'Sunrisers Hyderabad','Mumbai Indians',1,4,'Mohammad Nabi','MJ Guptill','JJ Bumrah',1,0,0,0,0,0,0,0,0,'Mohammad Nabi','bowled','');        
drop table if exists super_over_balls;
create table if not exists super_over_balls as select * from deliveries where is_super_over = 1; 
alter TABLE super_over_balls drop COLUMN `over`, drop COLUMN is_super_over; 
update super_over_balls,teams set batting_team = team_short_name where super_over_balls.batting_team = teams.team_name;
update super_over_balls set bowling_team = (select team_short_name from teams where super_over_balls.bowling_team = teams.team_name);
delete from deliveries where is_super_over = 1;
alter TABLE deliveries drop column is_super_over, drop COLUMN batting_team, drop COLUMN bowling_team; 

-- Add rows for super_overs in 2020 season

#################### REFORMATTING DELIVERIES BASE TABLE TO MAKE IT COHERENT WITH THE NEW_DELIVERIES DATASET ####################
alter table deliveries add column extras_type varchar(20) default null after total_runs;
update deliveries set extras_type = 'byes' where bye_runs != 0;
update deliveries set extras_type = 'wides' where wide_runs != 0;
update deliveries set extras_type = 'legbyes' where legbye_runs != 0;
update deliveries set extras_type = 'penalty' where penalty_runs != 0;
alter table deliveries drop column legbye_runs, drop column bye_runs, drop column wide_runs,drop column penalty_runs;
update deliveries set extras_type = 'byes', noball_runs = 1 where noball_runs >1;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/new_deliveries2020.csv' -- add your own path here
into table deliveries
fields terminated by ','
enclosed by '"' lines
terminated by '\n'
ignore 1 lines;

update deliveries set extras_type = null where extras_type = '';
update deliveries set extras_type = null where extras_type = 'noballs';
update deliveries set player_dismissed = null where player_dismissed = '';
update deliveries set dismissal_kind = null where dismissal_kind = '';
update deliveries set fielder = null where fielder = '\r';

#################### HOME/ AWAY, DAY/ NIGHT, INNINGS SCORE ADDITION IN MATCHES ####################
alter table matches add column `time` varchar(5) default 'night' after date,
					add column team1_match_type varchar(10) default 'neutral' after toss_winner,
					add column team2_match_type varchar(10) default 'neutral' after team1_match_type,
                    add column team1_runs mediumint default 0 after winner,
                    add column team1_wickets smallint default 0 after team1_runs,
                    add column team1_overs DECIMAL(3,1) default 0.0 after team1_wickets,
                    add column team2_runs mediumint default 0 after team1_overs,
                    add column team2_wickets smallint default 0 after team2_runs,
                    add column team2_overs DECIMAL(3,1) default 0.0 after team2_wickets;

update matches as t1 join (select date, min(match_id) min_id from matches group by date having count(match_id) >1) as t2 on t1.match_id = t2.min_id set time = 'day'; 

create temporary table matches2 (final_date date not null);
insert into matches2
select max(date) from matches group by year(date) order by date;
update matches as t1 set team1_match_type = 'final', team2_match_type = 'final' where date in (select * from matches2); 
drop table matches2;

update matches set team1_match_type = '3rd place', team2_match_type = '3rd place' where match_id = 174;
update matches set team1_match_type = 'semifinals', team2_match_type = 'semifinals' where team1_match_type != 'final' and ((date> '2008-05-28' and year(date) = 2008) or (date> '2009-05-21' and year(date) = 2009) or (date> '2010-04-19' and year(date) = 2010));
update matches set team1_match_type = 'eliminator', team2_match_type = 'eliminator' where team1_match_type != 'final' and ((date> '2011-05-23' and year(date) = 2011) or (date> '2012-05-21' and year(date) = 2012) or (date> '2013-05-20' and year(date) = 2013) or (date> '2014-05-27' and year(date) = 2014) or (date> '2015-05-18' and year(date) = 2015) or (date> '2016-05-23' and year(date) = 2016) or (date> '2017-05-15' and year(date) = 2017) or (date> '2018-05-21' and year(date) = 2018) or (date> '2019-05-06' and year(date) = 2019) or (date> '2020-11-04' and year(date) = 2020));

-- updating home and away values based on instances where home_stadium1 values match
update matches join venues as v using (venue_id) left join teams as t on t.home_stadium1 = v.venue_id and t.team_id = t.parent_team_id set team1_match_type = 
	case when batting_team1 = team_short_name then 'home'
		 when batting_team2 = team_short_name then 'away'
         else team1_match_type
         end where team1_match_type not in ('final', 'semifinals', '3rd place', 'eliminator');

-- Reusable query         
update matches set team2_match_type = case 
		when team1_match_type='home' then 'away' 
        when team1_match_type = 'away' then 'home' 
        else team2_match_type end;
        
-- updating home and away values based on instances where home_stadium2 values match        
update matches join venues as v using (venue_id) left join teams as t on t.home_stadium2 = v.venue_id and t.team_id = t.parent_team_id 
	set team1_match_type = case 
		when batting_team2 = team_short_name then 'away' 
        when batting_team1 = team_short_name then 'home' 
        else 'neutral'
    end where team1_match_type = 'neutral' and nation ='India' and (year(date) = 2008 or venue_id in (97,82, 85, 90));
    
-- 3rd+ home stadium cases (update as these are old values)
-- CSK 65 in 2018, 94 in 2014
-- RR 85 in 2015
-- KXIP 67 in 2017,2018, 65 in 2015
-- MI 85 in 2010, 91 in 2016
-- SRH 76,88 in 2010 (manually update some cases), 87 in 2010,12, 91 in 2012,15,16,19
-- KTK 67 in 2011  
-- RPS 76 in 2011, 91 in 2016, 92 (2012-13) main then 65 (RPS times)
-- KKR 94 in 2013
update matches set team1_match_type = case 
		when year(date) =2010 and venue_id in (72,83,84) then if (batting_team1 = 'SRH', 'home', 'away') 
		when year(date) =2010 and venue_id = 81 then if (batting_team1 = 'MI', 'home', 'away') 
		when year(date) =2011 and venue_id = 87 then if (batting_team1 = 'KTK', 'home', 'away') 
		when year(date) =2011 and venue_id = 72 then if (batting_team1 = 'RPS', 'home', 'away') 
		when year(date) =2012 and venue_id in (83,88) then if (batting_team1 = 'SRH', 'home', 'away') 
		when year(date) =2013 and venue_id = 91 then if (batting_team1 = 'KKR', 'home', 'away') 
		when year(date) =2014 and venue_id = 91 then if (batting_team1 = 'CSK', 'home', 'away') 
		when year(date) =2015 and venue_id = 88 then if (batting_team1 = 'SRH', 'home', 'away') 
		when year(date) =2015 and venue_id = 81 then if (batting_team1 = 'RR', 'home', 'away') 
		when year(date) =2015 and venue_id = 95 then if (batting_team1 = 'KXIP', 'home', 'away')
        when year(date) = 2016 and venue_id = 88 then if (batting_team1 = 'MI', 'home', 'away')
        when year(date) = 2016 and venue_id = 88 then if (batting_team2 = 'MI', 'away', 'home')
        when year(date) = 2016 and venue_id = 88 then if (batting_team1 = 'RPS', 'home', 'away')
        when year(date) = 2016 and venue_id = 88 then if (batting_team2 = 'RPS', 'away', 'home')
		when year(date) in (2016,2017) and venue_id = 95 then if (batting_team1 = 'RPS', 'home', 'away') 
 		when year(date) in (2017,2018) and venue_id = 87 then if (batting_team1 = 'KXIP', 'home', 'away') 
 		when year(date) =2018 and venue_id = 95 then if (batting_team1 = 'CSK', 'home', 'away') 
        else 'neutral'
    end where team1_match_type = 'neutral' and year(date)!= 2009;

-- 20 matches in UAE in 2014 and 3 other neutral matches = 23 neutral matches 
select * from matches where team1_match_type = team2_match_type and year(date) not in (2009,2020) and team1_match_type = 'neutral';
