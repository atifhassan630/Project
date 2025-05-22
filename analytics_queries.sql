################ SOME USEFUL QUERIES (NOT STORED AS VIEWS) ##################
select match_id, inning, max(`over`) max_over, floor(count(ball)/6) + round((count(ball)%6)/10,1) overs from deliveries where wide_runs=0 and noball_runs=0 group by match_id, inning;

select * from match_bowler_scorecards order by maidens + near_maidens desc; 

-- ball possible outcomes grouping (improve and consider all cases)
-- legal balls + no wickets
select batsman_runs, extra_runs, legbye_runs, bye_runs,penalty_runs, count(*) from deliveries where player_dismissed is null and wide_runs = 0 and noball_runs = 0 GROUP BY batsman_runs,legbye_runs, bye_runs, penalty_runs order by batsman_runs, extra_runs, legbye_runs;
-- legal balls + wickets
select batsman_runs, extra_runs, legbye_runs, bye_runs, count(*), dismissal_kind from deliveries where player_dismissed is not null and wide_runs = 0 and noball_runs = 0 GROUP BY batsman_runs,legbye_runs, bye_runs, dismissal_kind order by batsman_runs, extra_runs, legbye_runs; 
-- wide balls + no wickets
select wide_runs, count(*) from deliveries where player_dismissed is null and wide_runs != 0 GROUP BY wide_runs order by wide_runs;
-- wide balls + wickets
select wide_runs, count(*), dismissal_kind from deliveries where player_dismissed is not null and wide_runs != 0 GROUP BY wide_runs,dismissal_kind order by wide_runs;
-- no balls + wickets
select noball_runs, batsman_runs, count(*), dismissal_kind from deliveries where player_dismissed is not null and noball_runs != 0 GROUP BY noball_runs,batsman_runs,dismissal_kind order by extra_runs,batsman_runs;
-- no balls + no wickets -- ERROR -- 16 cases of noball_runs > 1, all for seasons < 2018 
select noball_runs, batsman_runs, count(*) from deliveries where player_dismissed is null and noball_runs != 0 GROUP BY noball_runs,batsman_runs order by extra_runs, batsman_runs;
-- Can be further split according to 1. innings, 2. group stage and playoffs, 3. teams, 4. venues, 5. by nationality of batsmen 



################ BOWLER ANALYTICS ##################
-- bowler stats in depth. subtract extras runs if you want
select bowler,max(runs_conceded),count(*) innings,sum(fours) + sum(sixes) boundaries,sum(wickets) wickets, round(sum(runs_conceded)/sum(balls)*6,2) economy_rate,count(case when runs_conceded >= 50 then 1 else null end) as dinda_innings from match_bowler_scorecards group by bowler having innings > 16 order by economy_rate; 
-- bowler stats in depth split into seasons. A new column for performance score can be added
select season, bowler,max(runs_conceded),count(*) innings, sum(wickets) wickets, round(sum(runs_conceded)/sum(balls)*6,2) economy_rate,count(case when runs_conceded >= 50 then 1 else null end) as dinda_innings from match_bowler_scorecards as b join matches as m using (match_id) group by bowler,season having innings > 6 order by economy_rate; 

-- CASES WHERE BOWLER DOT BALL % LESS THAN AVG DOT BALL % AT THAT VENUE



-- top 150 batsman
-- top 150 bowlers
-- top 50 young players
-- major batsmen against major bowlers (include power play vs non-power play)
-- young players against major batsmen (include power play vs non-power play)
-- young players against major bowlers (include power play vs non-power play)