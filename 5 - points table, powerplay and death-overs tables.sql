#################### POINTS AND DETAILED_MATCHES TABLE####################
drop table if exists points_table;
drop table if exists detailed_matches;

CREATE TABLE IF NOT EXISTS points_table (
  entry_id int unsigned NOT NULL AUTO_INCREMENT,
  season mediumint NOT NULL,
  team varchar(45) NOT NULL,
  matches_played smallint DEFAULT 0,
  points smallint DEFAULT 0,
  wins smallint DEFAULT 0,
  losses smallint DEFAULT 0,
  no_results smallint DEFAULT 0,
  for_runs mediumint DEFAULT 0,
  for_wickets mediumint DEFAULT 0,
  for_balls mediumint DEFAULT 0,
  for_overs decimal(5,1) DEFAULT 0.0,
  away_runs mediumint DEFAULT 0,
  away_wickets mediumint DEFAULT 0,
  away_balls mediumint DEFAULT 0,
  away_overs decimal(5,1) DEFAULT 0.0,
  net_run_rate decimal(5,4) as (for_runs/for_overs - away_runs/away_overs),
  tosses_won smallint DEFAULT 0,
  longest_win_streak smallint DEFAULT 0,
  longest_loss_streak smallint DEFAULT 0,
  potm_awards smallint DEFAULT 0,
  PRIMARY KEY (entry_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS detailed_matches (
  entry_id int NOT NULL AUTO_INCREMENT,
  team varchar(5) DEFAULT NULL,
  match_id mediumint DEFAULT NULL,
  match_date date DEFAULT NULL,
  -- USE LAG FUNCTION TO CALCULATE REST
  match_time varchar(5) DEFAULT NULL,
  match_type varchar(20) DEFAULT NULL,
  opponent varchar(5) DEFAULT NULL,
  toss_win smallint DEFAULT NULL,
  inning smallint DEFAULT NULL,
  winner varchar(5) DEFAULT NULL,
  result_type varchar(20) DEFAULT NULL,
  res_margin_type varchar(10) DEFAULT NULL,
  result_margin int DEFAULT 0,
  points smallint DEFAULT 0,
  for_total_runs smallint unsigned DEFAULT 0,
  for_total_wickets smallint DEFAULT 0,
  for_total_overs decimal(3,1) DEFAULT 0,
  opp_total_runs smallint unsigned DEFAULT 0,
  opp_total_wickets smallint DEFAULT 0,
  opp_total_overs decimal(3,1) DEFAULT 0,
  for_pp_runs smallint unsigned DEFAULT 0,
  for_pp_wickets smallint DEFAULT 0,
  -- for_pp_overs decimal(3,1) DEFAULT 0.0,
  for_middle_runs smallint unsigned DEFAULT 0,
  for_middle_wickets smallint DEFAULT 0,
  for_death_runs smallint unsigned DEFAULT 0,
  for_death_wickets smallint DEFAULT 0,
  opp_pp_runs smallint unsigned DEFAULT 0,
  opp_pp_wickets smallint DEFAULT 0,
  opp_middle_runs smallint unsigned DEFAULT 0,
  opp_middle_wickets smallint DEFAULT 0,
  opp_death_runs smallint unsigned DEFAULT 0,
  opp_death_wickets smallint DEFAULT 0,
  PRIMARY KEY (entry_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

#################### UPDATING POINTS AND DETAILED_MATCHES TABLE USING STORED PROCEDURE ####################
DROP PROCEDURE if exists getSeasonStats;
DELIMITER $$
CREATE PROCEDURE getSeasonStats (IN  team varchar(10))
BEGIN 

-- FOR NET RUN RATE CALCULATION (NOT CONSIDERING DL-APPLIED/ NO-RESULT MATCHES)
-- If a teams gets all out within X (<20) overs, irrespective of the innings, then it will be counted as 20 overs 
-- Howeverm if a team successfully chases a target, then the overs added in their For (and opponent's away) tally will be the overs required by them to chase the total 

drop table if exists team_stats;
create temporary table team_stats
select batting_team1, match_id, `date`,`time`, team1_match_type, batting_team2 as opponent, if(toss_winner = team,1,0) toss_win, 1 as inning, winner, result_type, win_type, win_margin,
	(case when winner = team then 2 when winner ='NR' then 1 else 0 end) points, 
    team1_runs for_runs, team1_wickets for_wickets, if(team1_wickets != 10, team1_overs, 20.0) as for_overs, floor(if(team1_wickets != 10, floor(team1_overs)*6 + (team1_overs*10)%10, 120)) as for_balls,
    team2_runs opp_runs, team2_wickets opp_wickets, if(team2_wickets != 10, team2_overs, 20.0) as opp_overs, floor(if(team2_wickets != 10, floor(team2_overs)*6 + (team2_overs*10)%10, 120)) as opp_balls,
    coalesce(sum(case when inning = 1 and team_overs < 6.1 then total_runs else null end),0) for_pp_runs,
    count(case when inning = 1 and team_overs < 6.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_pp_wickets,
    coalesce(sum(case when inning = 1 and team_overs > 6.0 and team_overs < 17.1 then total_runs else null end),0) for_middle_runs,
    count(case when inning = 1 and team_overs > 6.0 and team_overs < 17.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_middle_wickets,
    coalesce(sum(case when inning = 1 and team_overs > 17.0 then total_runs else null end),0) for_death_runs,
    count(case when inning = 1 and team_overs > 17.0 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_death_wickets,
    coalesce(sum(case when inning = 2 and team_overs < 6.1 then total_runs else null end),0) opp_pp_runs,
    count(case when inning = 2 and team_overs < 6.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_pp_wickets,
    coalesce(sum(case when inning = 2 and team_overs > 6.0 and team_overs < 17.1 then total_runs else null end),0) opp_middle_runs,
    count(case when inning = 2 and team_overs > 6.0 and team_overs < 17.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_middle_wickets,
    coalesce(sum(case when inning = 2 and team_overs > 17.0 then total_runs else null end),0) opp_death_runs,
    count(case when inning = 2 and team_overs > 17.0 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_death_wickets
    from matches m left join deliveries using (match_id) WHERE batting_team1 = team and team1_match_type not in ('final','3rd place','semifinals','eliminator') group by match_id 
union 
select batting_team2, match_id, `date`,`time`, team2_match_type, batting_team1 as opponent, if(toss_winner = team,1,0) toss_win, 2 as inning, winner, result_type, win_type, win_margin,
	(case when winner = team then 2 when winner ='NR' then 1 else 0 end) points, 
    team2_runs for_runs, team2_wickets for_wickets, if(team2_wickets != 10, team2_overs, 20.0) as for_overs, floor(if(team2_wickets != 10, floor(team2_overs)*6 + (team2_overs*10)%10, 120)) as for_balls,
    team1_runs opp_runs, team1_wickets opp_wickets, if(team1_wickets != 10, team1_overs, 20.0) as opp_overs, floor(if(team1_wickets != 10, floor(team1_overs)*6 + (team1_overs*10)%10, 120)) as opp_balls,
    coalesce(sum(case when inning = 2 and team_overs < 6.1 then total_runs else null end),0) for_pp_runs,
    count(case when inning = 2 and team_overs < 6.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_pp_wickets,
    coalesce(sum(case when inning = 2 and team_overs > 6.0 and team_overs < 17.1 then total_runs else null end),0) for_middle_runs,
    count(case when inning = 2 and team_overs > 6.0 and team_overs < 17.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_middle_wickets,
    coalesce(sum(case when inning = 2 and team_overs > 17.0 then total_runs else null end),0) for_death_runs,
    count(case when inning = 2 and team_overs > 17.0 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) for_death_wickets,
    coalesce(sum(case when inning = 1 and team_overs < 6.1 then total_runs else null end),0) opp_pp_runs,
    count(case when inning = 1 and team_overs < 6.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_pp_wickets,
    coalesce(sum(case when inning = 1 and team_overs > 6.0 and team_overs < 17.1 then total_runs else null end),0) opp_middle_runs,
    count(case when inning = 1 and team_overs > 6.0 and team_overs < 17.1 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_middle_wickets,
    coalesce(sum(case when inning = 1 and team_overs > 17.0 then total_runs else null end),0) opp_death_runs,
    count(case when inning = 1 and team_overs > 17.0 and player_dismissed is not null and dismissal_kind != 'retired hurt' then player_dismissed else null end) opp_death_wickets
    from matches m left join deliveries using (match_id) WHERE batting_team2 = team and team2_match_type not in ('final','3rd place','semifinals','eliminator') group by match_id ;


insert into detailed_matches (team, match_id, match_date, match_time, match_type, opponent, toss_win, inning, winner, result_type, res_margin_type, result_margin, points, for_total_runs, for_total_wickets, for_total_overs, opp_total_runs, opp_total_wickets, opp_total_overs, for_pp_runs, for_pp_wickets, for_middle_runs, for_middle_wickets, for_death_runs, for_death_wickets,  opp_pp_runs, opp_pp_wickets, opp_middle_runs, opp_middle_wickets, opp_death_runs, opp_death_wickets)
select batting_team1, match_id, `date`, `time`, team1_match_type, opponent, toss_win, inning, winner, result_type, win_type, win_margin, points, for_runs, for_wickets, for_overs, opp_runs, opp_wickets, opp_overs, for_pp_runs, for_pp_wickets, for_middle_runs, for_middle_wickets, for_death_runs, for_death_wickets, opp_pp_runs, opp_pp_wickets, opp_middle_runs, opp_middle_wickets, opp_death_runs, opp_death_wickets from team_stats order by date;

insert into points_table (season, team, matches_played, points, wins, losses, no_results, for_runs, for_wickets, for_balls, away_runs, away_wickets, away_balls,tosses_won)
select year(date), batting_team1, count(match_id) played, sum(points) total_points, 
	count(case when points = 2 then 1 else null end) wins,
	count(case when points = 0 then 1 else null end) losses,
	count(case when points = 1 then 1 else null end) no_results,
    sum(case when (result_type = 'normal' or result_type = 'tie') then for_runs
		when result_type = 'DL applied' and points = 2 and inning = 1 then opp_runs + win_margin 
		when result_type = 'DL applied' and inning = 2 then for_runs
        when result_type = 'DL applied' and points = 0 and inning = 1 then opp_runs - if(win_type='runs',win_margin,1) else null end) runs_for, 
	sum(case when result_type != 'no result' then for_wickets else null end) wickets_for, 
    sum(case when (result_type = 'normal' or result_type = 'tie') then for_balls
		when result_type = 'DL applied' and points = 2 and inning = 1 then opp_balls 
		when result_type = 'DL applied' and inning = 2 then for_balls
        when result_type = 'DL applied' and points = 0 and inning = 1 then opp_balls + FLOOR(RAND()*(13))+3 else null end) balls_for,
    sum(case when result_type = 'normal' then opp_runs
		when result_type = 'DL applied' and points = 2 and inning = 2 then for_runs - if(win_type='runs',win_margin,1) 
		when result_type = 'DL applied' and inning = 1 then opp_runs
        when result_type = 'DL applied' and points = 0 and inning = 2 then for_runs + win_margin  else null end) runs_away, 
    sum(case when result_type != 'no result' then opp_wickets else null end) wickets_away, 
    sum(case when (result_type = 'normal' or result_type = 'tie') then for_balls
		when result_type = 'DL applied' and points = 2 and inning = 2 then for_balls + FLOOR(RAND()*(13))+3
		when result_type = 'DL applied' and inning = 1 then opp_balls
        when result_type = 'DL applied' and points = 0 and inning = 2 then for_balls else null end) balls_away,
    sum(toss_win) tosses_won from team_stats group by year(date);

drop table team_stats;
END $$
Delimiter ;

-- Loop team_short_name for each parent_id = team_id
call getSeasonStats('KKR');
call getSeasonStats('CSK');
call getSeasonStats('DC');
call getSeasonStats('MI');
call getSeasonStats('SRH');
call getSeasonStats('RPS');
call getSeasonStats('KTK');
call getSeasonStats('GC');
call getSeasonStats('RCB');
call getSeasonStats('KXIP');
call getSeasonStats('RR');

alter table points_table add column table_rank smallint default null after season;
update points_table set for_overs = round(floor(for_balls/6) + (for_balls%6)/10,1) , away_overs = round(floor(away_balls/6) + (away_balls%6)/10,1);
update points_table p join (SELECT season, team, points, net_run_rate, ROW_NUMBER() over (PARTITION BY season ORDER BY points desc, net_run_rate desc) t_rank from points_table) t on p.season = t.season and p.team = t.team set table_rank = t.t_rank ;
alter table points_table drop column for_balls, drop column away_balls;


#################### POWERPLAY AND DEATH-OVER TABLES ####################
CREATE VIEW powerplay_bowlers as
select match_id, inning, bowler, (floor(sum(balls)/6) + round((sum(balls)%6)/10,1)) overs, sum(balls) as balls,sum(maiden) maidens, (sum(near_maiden) - sum(maiden)) near_maidens, sum(runs) runs_conceded, sum(wickets) wickets, sum(dot_balls) dots, sum(singles) singles, sum(doubles) doubles, sum(triples) triples, sum(fours) fours, sum(sixes) sixes, sum(extras) - sum(wide_runs) - sum(noball_runs) bat_extras, sum(wide_runs) wide_runs, sum(noball_runs) noball_runs from (select match_id, inning, bowler, over_no, balls, runs, wickets, extras, dot_balls, singles, doubles, triples, fours, sixes, wide_runs, noball_runs, (runs = legbye_runs + bye_runs and balls = 6) maiden, (dot_balls > 4) near_maiden from match_over_scorecards join matches using (match_id) where over_no < 7 and result_type not in ('no result','DL applied')) as t group by match_id, inning, bowler; 

CREATE VIEW death_over_bowlers as 
select match_id, inning, bowler, (floor(sum(balls)/6) + round((sum(balls)%6)/10,1)) overs, sum(balls) as balls,sum(maiden) maidens, (sum(near_maiden) - sum(maiden)) near_maidens, sum(runs) runs_conceded, sum(wickets) wickets, sum(dot_balls) dots, sum(singles) singles, sum(doubles) doubles, sum(triples) triples, sum(fours) fours, sum(sixes) sixes, sum(extras) - sum(wide_runs) - sum(noball_runs) bat_extras, sum(wide_runs) wide_runs, sum(noball_runs) noball_runs from (select match_id, inning, bowler, over_no, balls, runs, wickets, extras, dot_balls, singles, doubles, triples, fours, sixes, wide_runs, noball_runs, (runs = legbye_runs + bye_runs and balls = 6) maiden, (dot_balls > 4) near_maiden from match_over_scorecards join matches using (match_id) where over_no > 16 and result_type not in ('no result','DL applied')) as t group by match_id, inning, bowler; 

CREATE VIEW middle_over_bowlers as
select match_id, inning, bowler, (floor(sum(balls)/6) + round((sum(balls)%6)/10,1)) overs, sum(balls) as balls,sum(maiden) maidens, (sum(near_maiden) - sum(maiden)) near_maidens, sum(runs) runs_conceded, sum(wickets) wickets, sum(dot_balls) dots, sum(singles) singles, sum(doubles) doubles, sum(triples) triples, sum(fours) fours, sum(sixes) sixes, sum(extras) - sum(wide_runs) - sum(noball_runs) bat_extras, sum(wide_runs) wide_runs, sum(noball_runs) noball_runs from (select match_id, inning, bowler, over_no, balls, runs, wickets, extras, dot_balls, singles, doubles, triples, fours, sixes, wide_runs, noball_runs, (runs = legbye_runs + bye_runs and balls = 6) maiden, (dot_balls > 4) near_maiden from match_over_scorecards join matches using (match_id) where over_no >= 6 and over_no <= 16 and result_type not in ('no result','DL applied')) as t group by match_id, inning, bowler; 

-- Add for DL applied matches with corresponding pp over values

drop table if exists death_over_batsmen;
create TABLE death_over_batsmen like match_batsman_scorecards;
alter table death_over_batsmen rename column batsman_inning_id TO batsman_do_id;

drop table if exists middle_over_batsmen;
create TABLE middle_over_batsmen like match_batsman_scorecards;
alter table middle_over_batsmen rename column batsman_inning_id TO batsman_mo_id;

drop table if exists powerplay_batsmen;
create TABLE powerplay_batsmen like match_batsman_scorecards;
alter table powerplay_batsmen rename column batsman_inning_id TO batsman_pp_id;

call getBatsmanStats('powerplay_batsmen', 1, 300, 1, 6);
call getBatsmanStats('powerplay_batsmen', 301, 600, 1, 6);
call getBatsmanStats('powerplay_batsmen', 601, 900, 1, 6);
call getBatsmanStats('middle_over_batsmen', 1, 300, 7, 16);
call getBatsmanStats('middle_over_batsmen', 301, 600, 7, 16);
call getBatsmanStats('middle_over_batsmen', 601, 900, 7, 16);
call getBatsmanStats('death_over_batsmen', 1, 300, 17, 20);
call getBatsmanStats('death_over_batsmen', 301, 600, 17, 20);
call getBatsmanStats('death_over_batsmen', 601, 900, 17, 20);

update powerplay_batsmen s join (select match_id, inning, sum(total_runs) as pp_runs from deliveries where `over` < 7 group by match_id, inning) m using (match_id, inning) set dismissal_type = 'NO', bowler = 'NO', runs_on_dismissal = m.pp_runs where s.dismissal_type is null;
update powerplay_batsmen set runs_on_arrival = 0, overs_on_arrival = 0.0 where position in (1,2);

-- first update positions from match_batsman_scorecard
update death_over_batsmen set runs_on_arrival = 0, overs_on_arrival = 0.0 where position in (1,2);

select * from powerplay_batsmen s join (select match_id, inning, sum(total_runs) as pp_runs from deliveries2 where `over` < 7 group by match_id, inning) m using (match_id, inning);

-- delete DL_applied matches and add them a fresh