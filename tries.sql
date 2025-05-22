select * from matches;
select * from deliveries;
select * from super_over_balls;
select * from teams;
select * from venues;
 
select * from match_over_scorecards;
select * from match_bowler_scorecards; 
select * from match_batsman_scorecards; 

select * from points_table order by season, table_rank;
select * from detailed_matches;

select * from players;
select * from no_matches_played;
select * from season_players_info;

SELECT * from powerplay_batsmen;
-- match_points:- Points for:
-- 1. Captaincy, 2. Batting (balls faced, str rate, 4, 6, dot ball rate), 3. Fielding, 4. Bowling (economy rate for each over based on stage of innings, dots, wickets, strike rotation, etc.), 5. Salary, 6. Supposed role (main XI, rotation, role player, young reserve)

start transaction;
rollback;
commit;

-- update deliveries set team_runs = total_runs, team_overs = if(noball_runs = 0 and (extras_type is null or extras_type in ('byes','legbyes')),0.1,0.0) where `over` = 1 and ball = 1;
-- rows between 1st ball of inning and current row --> generating team_runs (sum of total_runs) and team_overs(count legal balls and convert to overs using %6 and floor+/6)
-- update deliveries set team_runs = total_runs + lag(team_runs,1) over (PARTITION BY match_id) where `over` != 1 and ball != 1;