#################### PYTHON SCRIPT TO OBTAIN RUNNING TOTAL OF RUNS SCORED IN AN INNINGS & BATSMEN RUNS ####################
-- Instead of manually updating each row with the new values for striker_runs, striker_balls, non_striker_runs, non_striker_balls, team_runs, team_wickets and team_overs, reformatting the deliveries table in python and then reimporting the formatted deliveries.csv was found to be much faster (from ~10 hours to ~10 seconds).
###########################################################################################################################
drop table if exists deliveries;
CREATE TABLE if not exists deliveries (
  ball_id int unsigned NOT NULL AUTO_INCREMENT,
  match_id int unsigned NOT NULL,
  inning int DEFAULT NULL,
  `over` smallint NOT NULL,
  ball smallint NOT NULL,
  batsman varchar(30) NOT NULL,
  non_striker varchar(30) NOT NULL,
  bowler varchar(30) NOT NULL,
  noball_runs int DEFAULT 0,
  batsman_runs int DEFAULT 0,
  extra_runs int DEFAULT 0,
  total_runs int DEFAULT 0,
  extras_type varchar(20) default null,
  player_dismissed varchar(30) DEFAULT NULL,
  dismissal_kind varchar(30) DEFAULT NULL,
  fielder varchar(30) DEFAULT NULL,
  striker_runs SMALLINT unsigned default 0,
  striker_balls SMALLINT default 0,
  non_striker_runs SMALLINT unsigned default 0,
  non_striker_balls SMALLINT unsigned default 0,
  team_runs int DEFAULT 0,
  team_overs decimal(3, 1) default 0.0,
  PRIMARY KEY (ball_id)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci;

load data local infile 'D:/work/pythonPractice/big projects/IPL Analytics/work/datasets/f-deliveries.csv' -- add your own path here
into table deliveries 
fields terminated by ',' 
enclosed by '"' 
lines terminated by '\n' 
ignore 1 lines;

update deliveries set player_dismissed = null where player_dismissed = '';
update deliveries set dismissal_kind= null where dismissal_kind = '';
update deliveries set fielder = null where fielder = '';
update deliveries set extras_type = null where extras_type = '';
-- update deliveries set team_overs = replace(trim(trailing '\r' from team_overs),trim(trailing '\n' from team_overs),trim(trailing ' ' from team_overs));
-- update deliveries set fielder = replace(trim(trailing '\r' from fielder),trim(trailing '\n' from fielder),trim(trailing ' ' from fielder));

#################### BATSMAN SCORECARDS ####################
drop table if exists match_batsman_scorecards2;
drop table if exists match_batsman_scorecards;

CREATE TABLE IF NOT EXISTS match_batsman_scorecards2 (
    batsman_inning_id INT NOT NULL AUTO_INCREMENT,
    match_id INT NOT NULL,
    inning SMALLINT NOT NULL,
    batsman VARCHAR(45) NOT NULL,
    position SMALLINT NULL,
    runs SMALLINT UNSIGNED DEFAULT NULL,
    balls SMALLINT UNSIGNED DEFAULT NULL,
    dismissal_type VARCHAR(45) DEFAULT NULL,
    bowler VARCHAR(45) DEFAULT NULL,
    fielder VARCHAR(45) DEFAULT NULL,
    runs_on_arrival SMALLINT UNSIGNED DEFAULT NULL,
    overs_on_arrival DECIMAL(3,1) DEFAULT NULL,
    runs_on_dismissal SMALLINT UNSIGNED DEFAULT NULL,
    overs_on_dismissal DECIMAL(3 , 1 ) DEFAULT NULL,
    end_partner_runs SMALLINT DEFAULT NULL,
    end_partner_balls SMALLINT DEFAULT NULL,
    dot_balls SMALLINT DEFAULT NULL,
    singles SMALLINT DEFAULT NULL,
    doubles SMALLINT DEFAULT NULL,
    triples SMALLINT DEFAULT NULL,
    fours SMALLINT DEFAULT NULL,
    fives SMALLINT DEFAULT NULL,
    sixes SMALLINT DEFAULT NULL,
    PRIMARY KEY (batsman_inning_id)
)  ENGINE=INNODB DEFAULT CHARSET=UTF8MB4 COLLATE = UTF8MB4_0900_AI_CI;

##########################################################################################################
DROP PROCEDURE if exists getBatsmanStats;
DELIMITER $$
CREATE PROCEDURE getBatsmanStats (IN  tableName varchar(25), IN  startMatch int, IN  endMatch int, IN  startOver int, IN  endOver int)
BEGIN 
	drop table if exists strike_min, non_strike_min, position_sort, inning_stats, dismissal_stats;
    
    set @insertQuery = CONCAT('insert into ', tableName, '(match_id, inning, batsman, position, runs, balls, dismissal_type, bowler, fielder, runs_on_arrival, overs_on_arrival,runs_on_dismissal, overs_on_dismissal, end_partner_runs, end_partner_balls, dot_balls, singles, doubles, triples, fours,fives, sixes)
    select p.match_id, p.inning, p.batsman,p.str_order, coalesce(i.runs,0), coalesce(i.balls,0), d.dismissal_kind, d.bowler, d.fielder, p.runs_on_arrival, p.overs_on_arrival, d.team_runs as runs_on_dismissal, d.team_overs as overs_on_dismissal, d.end_partner_runs, d.end_partner_balls, coalesce(i.dots,0), coalesce(i.singles,0), coalesce(i.doubles,0), coalesce(i.triples,0), coalesce(i.fours,0), coalesce(i.fives,0), coalesce(i.sixes,0) from position_sort p left join inning_stats i on i.match_id = p.match_id and i.inning = p.inning and i.batsman = p.batsman left join dismissal_stats d on d.match_id = p.match_id and d.inning = p.inning and d.batsman = p.batsman');
    
    create TEMPORARY table inning_stats 
	select match_id, inning, batsman, sum(batsman_runs) runs, count(case when noball_runs = 0 and (extras_type is null or extras_type not like 'wide%') then 1 else null end) balls, count(case when total_runs = 0 or (extras_type = 'byes' and noball_runs = 0) or (extras_type = 'legbyes' and noball_runs = 0) then 1 else null end) dots, count(case when batsman_runs = 1 then 1 else null end) singles, count(case when batsman_runs = 2 then 1 else null end) doubles, count(case when batsman_runs = 3 then 1 else null end) triples, count(case when batsman_runs = 4 then 1 else null end) fours, count(case when batsman_runs = 5 then 1 else null end) fives, count(case when batsman_runs = 6 then 1 else null end) sixes from deliveries where (match_id between startMatch and endMatch) and (`over` between startOver and endOver) group by match_id,inning, batsman;
    
    create TEMPORARY table non_strike_min
    select match_id, inning, non_striker, min(team_overs) as str_min, min(team_runs) as min_truns, 2 as pos from deliveries where (match_id between startMatch and endMatch) and (`over` between startOver and endOver) GROUP BY match_id, inning, non_striker;
    create TEMPORARY table strike_min
    select match_id, inning, batsman, min(team_overs) as str_min, min(team_runs) as min_truns, 1 as pos from deliveries where (match_id between startMatch and endMatch) and (`over` between startOver and endOver) GROUP BY match_id, inning, batsman; 
    create TEMPORARY table position_sort
	select match_id, inning, batsman, min(str_min) overs_on_arrival, min(min_truns) as runs_on_arrival, pos, ROW_NUMBER() OVER (PARTITION BY match_id, inning ORDER BY min(str_min),pos) as str_order from (select * from strike_min UNION select * from non_strike_min order by match_id, inning, str_min) as d GROUP BY match_id, inning, batsman;
    
    create TEMPORARY table dismissal_stats
	select match_id, inning, batsman, dismissal_kind, bowler, fielder, player_dismissed, non_striker_runs as end_partner_runs, non_striker_balls as end_partner_balls, team_runs, team_overs from deliveries where player_dismissed is not null and player_dismissed = batsman and (match_id between startMatch and endMatch) and (`over` between startOver and endOver) union
select match_id, inning, non_striker, dismissal_kind, bowler, fielder, player_dismissed, striker_runs as end_partner_runs, non_striker_balls as end_partner_balls, team_runs,team_overs from deliveries where player_dismissed is not null and player_dismissed != batsman and (match_id between startMatch and endMatch) and (`over` between startOver and endOver);
    
    PREPARE insStmt from @insertQuery;
    EXECUTE insStmt;
    DEALLOCATE PREPARE insStmt;
    
    drop table strike_min, non_strike_min, position_sort, inning_stats, dismissal_stats;
	
END$$
DELIMITER ;

call getBatsmanStats('match_batsman_scorecards2', 1, 50, 1, 20);
call getBatsmanStats('match_batsman_scorecards2', 51,150, 1, 20);
call getBatsmanStats('match_batsman_scorecards2', 151,300, 1, 20);
call getBatsmanStats('match_batsman_scorecards2', 301,500, 1, 20);
call getBatsmanStats('match_batsman_scorecards2', 501,900, 1, 20);

update match_batsman_scorecards2 s join matches m using (match_id) set dismissal_type = 'NO', bowler = 'NO', runs_on_dismissal = m.team1_runs, overs_on_dismissal = m.team1_overs where s.inning =1 and s.dismissal_type is null and overs_on_arrival <= 20.0;
update match_batsman_scorecards2 s join matches m using (match_id) set dismissal_type = 'NO', bowler = 'NO', runs_on_dismissal = m.team2_runs, overs_on_dismissal = m.team2_overs where s.inning =2 and s.dismissal_type is null and overs_on_arrival <= 20.0;
update match_batsman_scorecards2 set runs_on_arrival = 0, overs_on_arrival = 0.0 where position in (1,2);

-- solve the issue where dismissal_over and arrival_over of next batsman differ

-- batsmen that got retired hurt but later came back to bat again
SELECT match_id, inning, batsman, dismissal_type, position from match_batsman_scorecards2 group by match_id, inning, batsman having count(batsman) >1;

create table match_batsman_scorecards like match_batsman_scorecards2;

#################################################
-- PYTHON SCRIPT FOR COMPLETING MATCH-DAY SQUADS
#################################################
drop table match_batsman_scorecards2;
-- dude has been renamed in the dataset but not in the match_squads of the json dataset
update match_batsman_scorecards set batsman = 'HS Baddhan' where match_id = 334 and inning = 1 and batsman = 'Harmeet Singh';

-- innings with 2 batsmen not out in the end
-- SELECT match_id, inning, count(batsman) not_out from match_batsman_scorecards where dismissal_type is null group by match_id, inning having not_out>1)
-- update end_partner_runs for these cases

#################### OVER AND BOWLER SCORECARDS ####################
drop table if exists match_over_scorecards;
drop table if exists match_bowler_scorecards;

CREATE TABLE IF NOT EXISTS match_over_scorecards (
  over_id int NOT NULL AUTO_INCREMENT,
  match_id int NOT NULL,
  inning smallint NOT NULL,
  bowler varchar(45) NOT NULL,
  over_no smallint NOT NULL,
  balls smallint NOT NULL,
  runs smallint unsigned DEFAULT '0',
  wickets smallint unsigned DEFAULT '0',
  extras smallint unsigned DEFAULT '0',
  dot_balls smallint unsigned DEFAULT '0',
  singles smallint unsigned DEFAULT '0',
  doubles smallint unsigned DEFAULT '0',
  triples smallint unsigned DEFAULT '0',
  fours smallint unsigned DEFAULT '0',
  fives smallint unsigned DEFAULT '0',
  sixes smallint unsigned DEFAULT '0',
  wide_runs smallint unsigned DEFAULT '0',
  noball_runs smallint unsigned DEFAULT '0',
  legbye_runs smallint unsigned DEFAULT '0',
  bye_runs smallint unsigned DEFAULT '0',
  penalty_runs smallint unsigned DEFAULT '0',
  PRIMARY KEY (over_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- runs = legbye_runs + bye_runs and balls = 6 for MAIDEN OVER

#################### OVER-STATS STORED PROCEDURE ####################
DROP PROCEDURE if exists getOverStats;
DELIMITER $$
CREATE PROCEDURE getOverStats (IN  startMatchID int, IN  endMatchID int)
BEGIN 
	drop table if exists wicket;
	drop table if exists run;
	drop table if exists dot;
	
    create temporary table wicket select match_id,inning, bowler, `over` overs, count(case when player_dismissed is null then null else 1 end ) wickets FROM deliveries d WHERE d.match_id between startMatchID and endMatchID group by match_id,inning, `over`;
	
    create temporary table run select match_id,inning, bowler, `over` overs, count(case when (extras_type not in ('wides','wides (p)') or extras_type is null) and noball_runs =0 then 1 else null end) balls, sum(total_runs) runs, sum(extra_runs) extras, count(case when batsman_runs != 1 then null else 1 end ) singles, count(case when batsman_runs != 2 then null else 1 end) doubles, count(case when batsman_runs != 3 then null else 1 end) triples, count(case when batsman_runs != 4 then null else 1 end) fours, count(case when batsman_runs != 6 then null else 1 end ) sixes, count(case when batsman_runs != 5 then null else 1 end) fives, 
    sum(case when extras_type like 'wide%' then extra_runs else 0 end) wides, sum(noball_runs) noballs, sum(case when extras_type = 'legbyes' and noball_runs =0 then extra_runs when extras_type = 'legbyes' and noball_runs = 1 then extra_runs-1 else 0 end) legbyes, sum(case when extras_type = 'byes' and noball_runs =0 then extra_runs when extras_type = 'byes' and noball_runs = 1 then extra_runs-1 else 0 end) byes, sum(case when extras_type = 'penalty' then extra_runs else 0 end) penalty_runs 
    FROM deliveries d WHERE d.match_id between startMatchID and endMatchID group by match_id,inning, `over`;
	
    create temporary table dot select match_id,inning, bowler, `over` overs, count(case when total_runs = 0 or (extras_type = 'byes' and noball_runs = 0) or (extras_type = 'legbyes' and noball_runs = 0) then 1 else null end) dots FROM deliveries d WHERE d.match_id between startMatchID and endMatchID group by match_id,inning, `over`;
        
	INSERT INTO match_over_scorecards (match_id,inning, bowler, over_no, balls, runs, wickets,extras, dot_balls,singles, doubles, triples, fours, fives, sixes, wide_runs,noball_runs,legbye_runs,bye_runs,penalty_runs)
select w.match_id, w.inning, w.bowler, w.overs, r.balls, r.runs, w.wickets,r.extras, d.dots, r.singles, r.doubles, r.triples, r.fours, r.fives, r.sixes, wides, noballs, legbyes, byes, penalty_runs from wicket w join run r on w.match_id =r.match_id and w.inning= r.inning and w.bowler= r.bowler and w.overs = r.overs join dot d on r.match_id =d.match_id and r.inning= d.inning and r.bowler= d.bowler and r.overs = d.overs ;
    
END$$
DELIMITER ;
-- observe the execution times for each case
call getOverStats(1,100);
call getOverStats(101,250);
call getOverStats(251,500);
call getOverStats(501,900);

alter table match_over_scorecards add column batting_team varchar(5) DEFAULT NULL after inning, add column bowling_team varchar(5) DEFAULT NULL after batting_team;
update match_over_scorecards join matches using (match_id) set batting_team = if(inning = 1,batting_team1, batting_team2), bowling_team = if(inning = 2,batting_team1, batting_team2);

CREATE TABLE IF NOT EXISTS match_bowler_scorecards
select match_id, inning, batting_team, bowling_team, bowler, sum(balls) as balls, sum(maiden) maidens, (sum(near_maiden) - sum(maiden)) near_maidens, sum(runs) runs_conceded, sum(wickets) wickets, sum(dot_balls) dots, sum(singles) singles, sum(doubles) doubles, sum(triples) triples, sum(fours) fours, sum(sixes) sixes, sum(extras) - sum(wide_runs) - sum(noball_runs) bat_extras, sum(wide_runs) wide_runs, sum(noball_runs) noball_runs from (select match_id, inning, batting_team, bowling_team, bowler, over_no, balls, runs, wickets, extras, dot_balls, singles, doubles, triples, fours, sixes, wide_runs, noball_runs, (runs = legbye_runs + bye_runs and balls = 6) maiden, (dot_balls > 4) near_maiden from match_over_scorecards) as t group by match_id, inning, bowler; 
ALTER TABLE match_bowler_scorecards add COLUMN bowler_inning_id int NOT NULL AUTO_INCREMENT PRIMARY KEY FIRST, add column overs decimal (3,1) as (floor(balls/6) + round((balls%6)/10,1)) AFTER bowler;

-- run and extras per over test
select match_id, inning, over_no, runs, (singles + 2*doubles + 3*triples + 4*fours + 6*sixes + 5*fives + extras) as run_c, runs = (singles + 2*doubles + 3*triples + 4*fours + 6*sixes  + 5*fives + extras) as run_test, extras, (wide_runs + noball_runs + legbye_runs + bye_runs + penalty_runs) as extra_c, extras = (wide_runs + noball_runs + legbye_runs + bye_runs + penalty_runs) as extra_test from match_over_scorecards group by match_id, inning, over_no HAVING extra_test != 1 or run_test != 1; 

-- verify whether overs bowled in each innings matches with team1_overs and team2_overs of matches

-- :) DINDA ACADEMY (take average of how many boundaries these bowlers concede in a match vs the best bowlers)
select match_id, inning, bowler, sum(runs), sum(wickets), sum(dot_balls),sum(singles),sum(doubles),sum(triples),sum(fours), sum(fives), sum(sixes), sum(extras)  from match_over_scorecards group by match_id, inning, bowler having sum(runs) >= 50; 