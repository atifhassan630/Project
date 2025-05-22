#################### MANAGING DUPLICATE AND EXTRA BALLS ####################
-- duplicate balls or 10th ball error
select match_id, inning, `over`, ball,max(ball_id), count(ball) from deliveries group by match_id, inning, `over`, ball having count(ball) > 1; 
-- Out of these, for balls in seasons < 2018 or season = 2020, they are the 10th balls of the over but have been labelled as 1
UPDATE deliveries SET ball = 10 WHERE ball_id in (3716,19503,23669,49605,52179,79215,86626,110667,126783,186488); 
-- The rest are just duplicate balls (and are balls in seasons 2018 and 2019, so can be deleted using season-filter query) so deleting them
delete from deliveries where ball_id in (162806,162807,162871,162965,166611,167991,168081,169405,170111,170112,170118,170120,170121,171643,171686,172217,173345,174899,175559,175690,176029,177873,178862 );

-- Overs without 6 legal deliveries - extras balls considered normal balls(>6) or some balls are missing(<6)
select t1.match_id, t1.inning, t1.max_over, t2.`over`,minBall, maxBall, t2.left_over_balls, t1.max_over =  t2.`over` as test from
(select match_id, inning, max(`over`) as max_over from deliveries group by match_id, inning) as t1 join 
(select match_id, inning,`over`, min(ball_id) as minBall, max(ball_id) as maxBall, count(ball)-6 as left_over_balls from deliveries where noball_runs = 0 and (extras_type != 'wides' or extras_type is null) group by match_id, inning, `over` having count(ball) != 6) as t2 
on t1.match_id = t2.match_id and t1.inning = t2.inning where (t1.max_over =  t2.`over`) = 0;

-- updating some balls which were extras but were recorded as normal balls
update deliveries set extras_type = 'wides (p)' where ball_id =112094; -- 414
update deliveries set noball_runs = 1 where ball_id =180418; -- 870
update deliveries set noball_runs = 1 where ball_id =181123; -- 851
update deliveries set noball_runs = 1 where ball_id =181223; -- 851
update deliveries set noball_runs = 1 where ball_id =183500; -- 834
update deliveries set noball_runs = 1 where ball_id =183787; -- 848
UPDATE deliveries SET noball_runs = 1 WHERE ball_id = 187558; -- 837

-- inserting balls where over has 5 legal deliveries AFTER verifying with match commentaries and players' stats 
insert into deliveries (match_id, inning, `over`, ball, batsman, non_striker, bowler, noball_runs, batsman_runs, extra_runs, total_runs, player_dismissed, dismissal_kind, fielder) values 
(6,1,8,8,'JR Hopes','Yuvraj Singh','D Salunkhe',0,0,0,0,NULL,NULL,NULL),
(34,2,15,8,'AD Mascarenhas','SR Watson','A Mishra',0,0,0,0,NULL,NULL,NULL),
(180,1,6,4,'AM Nayar','Sunny Singh','M Kartik',0,0,0,0,NULL,NULL,NULL);
-- Deleting bizarre 7th ball in the source website that have been duplicated/ are dot balls
delete from deliveries where ball_id in (16897,30944,52947,151390,159867,166713); -- 72,133, 224, 7897,7933,11145

-- Updating cases where wickets have fallen and/or extras_ball and havent been registered into the file, leading to 7 legal deliveries balls 
update deliveries set player_dismissed = 'JJ Roy', dismissal_kind = 'stumped', fielder = 'KD Karthik', extra_runs = 1, extras_type = 'wides' where ball_id = 153404; -- 721
update deliveries set player_dismissed = 'Mandeep Singh', dismissal_kind = 'stumped', fielder = 'Ishan Kishan', extra_runs = 1, extras_type = 'wides' where ball_id = 153676; -- 722
update deliveries set player_dismissed = 'SR Watson', dismissal_kind = 'stumped', fielder = 'RR Pant',extra_runs = 1, extras_type = 'wides', batsman_runs = 0, total_runs = 1 where ball_id = 165872; -- 773, -- (does not include extra runs duplicated in batsman_runs and total_runs)
update deliveries set player_dismissed = 'C de Grandhomme', dismissal_kind = 'run out', fielder = 'B Kumar',batsman_runs = 1,total_runs = 2, extra_runs = 1, noball_runs = 1 where ball_id = 167430; -- 779, (includes extra runs duplicated in batsman_runs and total_runs)
update deliveries set batsman_runs = 0, extras_type = 'byes', extra_runs = 4, noball_runs = 1 where ball_id = 172382; -- 800, (does not include extra runs duplicated in batsman_runs and total_runs)
update deliveries set player_dismissed = 'S Dhawan', dismissal_kind = 'stumped', fielder = 'W Saha',extra_runs = 1, extras_type = 'wides', batsman_runs = 0, total_runs = 1 where ball_id = 178514; -- 826 (does not include extra runs duplicated in batsman_runs and total_runs) NOTE: not included in counting legal ball deliveries as it occurs in the max/last over
update deliveries set player_dismissed = 'DJ Hooda', dismissal_kind = 'run out', fielder = 'RR Pant',total_runs = 2, extra_runs = 1, extras_type = 'wides' where ball_id = 178465; -- 826, (includes extra runs duplicated in batsman_runs and total_runs)

-- for 2020 > seasons > 2017, extra_runs wrongly added to batsman runs as well .. hence, batsman_runs = batsman_runs - extra_runs
-- to check whether batsman runs are always getting added with extra_runs for season > 2017 for wide_runs, bye_runs, legbye_runs, noball_runs
select ball_id, match_id, inning, `over`, ball, batsman_runs, extra_runs, total_runs, extras_type, extra_runs = total_runs from deliveries where extra_runs != 0 and extras_type like 'wides%' and match_id >600;

update deliveries set batsman_runs = batsman_runs - extra_runs where (match_id between 709 and 828) and ball_id not in (165872,172382,178514);
update deliveries set total_runs = batsman_runs + extra_runs where (match_id between 709 and 828) and ball_id not in (165872,172382,178514);

-- balls with caught out wickets but fielder column is null
update deliveries set fielder = 'JP Duminy (sub)' where ball_id = 153677; -- 7907
-- 27 rows without fielder name but run out or catch out, will complete them in a future update

-- Cases of retired hurts not mentioned in the DB that would wreak havoc in the updated deliveries.csv created using python
update deliveries set player_dismissed = 'KC Sangakkara',dismissal_kind = 'retired hurt' where ball_id = 18894;
update deliveries set player_dismissed = 'SR Tendulkar',dismissal_kind = 'retired hurt' where ball_id = 49901;
update deliveries set player_dismissed = 'AC Gilchrist',dismissal_kind = 'retired hurt' where ball_id = 77689;
update deliveries set player_dismissed = 'SS Tiwary',dismissal_kind = 'retired hurt' where ball_id = 88924;
update deliveries set player_dismissed = 'S Dhawan', dismissal_kind = 'retired hurt' where ball_id = 98044;
update deliveries set player_dismissed = 'KM Jadhav', dismissal_kind = 'retired hurt' where ball_id = 150661;
update deliveries set player_dismissed = 'CH Gayle', dismissal_kind = 'retired hurt' where ball_id = 159861;
update deliveries set player_dismissed = 'R Salam', dismissal_kind = 'retired hurt' where ball_id = 165453;
update deliveries set player_dismissed = 'CA Lynn', dismissal_kind = 'retired hurt' where ball_id = 171642;

-- Nitin and Navdeep Saini
UPDATE deliveries d join matches using (match_id) set player_dismissed = 'Nitin Saini' where year(date) = 2012 and player_dismissed = 'N Saini'; -- 10
UPDATE deliveries d join matches using (match_id) set batsman = 'Nitin Saini' where year(date) = 2012 and batsman = 'N Saini'; -- 143
UPDATE deliveries d join matches using (match_id) set non_striker = 'Nitin Saini' where year(date) = 2012 and non_striker = 'N Saini'; -- 122
UPDATE deliveries d join matches using (match_id) set fielder = 'Nitin Saini' where year(date) = 2012 and fielder = 'N Saini\r'; -- 14

update deliveries set batsman = 'Arjun Yadav' where batsman = 'AS Yadav' and match_id BETWEEN 1 and 61; -- 40 times
update deliveries set non_striker = 'Arjun Yadav' where non_striker = 'AS Yadav' and match_id BETWEEN 1 and 61; -- 38 times
update deliveries set fielder = 'Arjun Yadav' where fielder = 'AS Yadav\r' and match_id BETWEEN 1 and 61; -- 2 times
update deliveries set player_dismissed = 'Arjun Yadav' where player_dismissed = 'AS Yadav' and match_id BETWEEN 1 and 61; -- 5 times

update deliveries set bowler = 'HS Baddhan' where bowler like '%(2)%'; -- 25 times

update deliveries set batsman = 'Abhishek Sharma' where batsman = 'Ankit Sharma' and match_id BETWEEN 751 and 828; -- 35 + 10 (2019)
update deliveries set non_striker = 'Abhishek Sharma' where non_striker = 'Ankit Sharma' and match_id BETWEEN 751 and 828; -- 23 + 12(2019)
update deliveries set fielder = 'Abhishek Sharma' where fielder = 'Ankit Sharma\r' and match_id BETWEEN 760 and 828; -- 1+ 1 
update deliveries set bowler = 'Abhishek Sharma' where bowler = 'Ankit Sharma' and match_id BETWEEN 769 and 828; -- 13 from 2019 season
update deliveries set player_dismissed = 'Abhishek Sharma' where player_dismissed = 'Ankit Sharma' and match_id BETWEEN 751 and 900; -- 1 + 2 

update deliveries set bowler = 'Arshdeep Singh' where bowler = 'A Singh' and match_id in (800, 816, 820); -- 65 from 2019 season

update deliveries set batsman = 'PR Barman' where batsman = 'P R Barman'; -- 25
update deliveries set non_striker = 'PR Barman' where non_striker = 'P R Barman'; -- 22 
update deliveries set bowler = 'PR Barman' where bowler = 'P R Barman'; -- 24
update deliveries set player_dismissed = 'PR Barman' where player_dismissed = 'P R Barman'; -- 779

with cte1 as 
(select year(m.date) season, batting_team1 team, batsman, sum(position) sum_pos, sum(case when position is not null then 1 else null end) innings, count(b.match_id) match_played from match_batsman_scorecards b join matches m on m.match_id = b.match_id WHERE inning =1 group by year(m.date), batting_team1, batsman), cte2 as 
(select year(m.date) season, batting_team2 team, batsman, sum(position) sum_pos, sum(case when position is not null then 1 else null end) innings, count(b.match_id) match_played from match_batsman_scorecards b join matches m on m.match_id = b.match_id WHERE inning =2 group by year(m.date), batting_team2, batsman)
select season, team, batsman, round((cte1.sum_pos + cte2.sum_pos)/(cte1.innings+ cte2.innings)) avg_pos, cte1.match_played + cte2.match_played matches_played from cte1 join cte2 using (season, team, batsman);


-- checking for duplicate names
with cte1 as
(select match_id, year(date) season, result_type, batsman, batting_team1 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, non_striker, batting_team1 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, bowler, batting_team1 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, fielder, batting_team1 from deliveries d join matches m using (match_id) where inning = 2 and fielder is not null and fielder not like '%(sub)%'), cte2 as
(select match_id, year(date) season, result_type, batsman, batting_team2 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, non_striker, batting_team2 from deliveries d join matches m using (match_id) where inning = 2 union
select match_id, year(date) season, result_type, bowler, batting_team2 from deliveries d join matches m using (match_id) where inning = 1 union
select match_id, year(date) season, result_type, fielder, batting_team2 from deliveries d join matches m using (match_id) where inning = 1  and fielder is not null and fielder not like '%(sub)%')
-- select season, batting_team1, batsman from cte1 union select season, batting_team2, batsman from cte2 ORDER BY season, batting_team1; -- SQUAD LIST FOR SEASON. Change order by to batsman, and batsman seasons will be obtained
-- select season, batting_team1, count(batsman) from (select season, batting_team1, batsman from cte1 union select season, batting_team2, batsman from cte2 ) as t group BY season, batting_team1; -- experimentations by season for each team
select match_id, season, batting_team1, result_type, count(batsman) tot from cte1 GROUP BY match_id, batting_team1 having tot!=11 union all select match_id, season, batting_team2, result_type, count(batsman) tot from cte2 GROUP BY match_id, batting_team2 having tot!=11; -- matches with errors in match_squads

-- find players playing for 2 teams in a single season
with cte1 as 
(select year(m.date) season, batting_team1 team, batsman, sum(position) sum_pos, sum(case when position is not null then 1 else null end) innings, count(b.match_id) match_played from match_batsman_scorecards b join matches m on m.match_id = b.match_id WHERE inning =1 group by year(m.date), batting_team1, batsman), cte2 as 
(select year(m.date) season, batting_team2 team, batsman, sum(position) sum_pos, sum(case when position is not null then 1 else null end) innings, count(b.match_id) match_played from match_batsman_scorecards b join matches m on m.match_id = b.match_id WHERE inning =2 group by year(m.date), batting_team2, batsman)
select season, batsman, count(cte1.team) as h, cte1.team from cte1 join cte2 using (season, batsman) group by season, batsman having h != 1;


#################### UPDATING MATCHES TABLE WITH INNINGS' SCORES ####################
update matches as m join (select match_id, sum(total_runs) as total1 from deliveries where inning = 1 group by match_id) as d on m.match_id = d.match_id set team1_runs = total1;
update matches as m join (select match_id, sum(total_runs) as total2 from deliveries where inning = 2 group by match_id) as d on m.match_id = d.match_id set team2_runs = total2;

-- can be combined by joining with 2 subqueries
update matches as m join (select match_id, floor(count(ball)/6) + round((count(ball)%6)/10,1) as overs from deliveries where noball_runs = 0 and (extras_type != 'wides' or extras_type is null) and inning=2 group by match_id) as d on m.match_id = d.match_id set team2_overs = overs;
update matches as m join (select match_id, floor(count(ball)/6) + round((count(ball)%6)/10,1) as overs from deliveries where noball_runs = 0 and (extras_type != 'wides' or extras_type is null) and inning=1 group by match_id) as d on m.match_id = d.match_id set team1_overs = overs;

update matches as m join (select match_id, count(ball) as wickets from deliveries where player_dismissed is not null and inning =1 and dismissal_kind != 'retired hurt' group by match_id) as d on m.match_id = d.match_id set team1_wickets = wickets;
update matches as m join (select match_id, count(ball) as wickets from deliveries where player_dismissed is not null and inning =2 and dismissal_kind != 'retired hurt' group by match_id) as d on m.match_id = d.match_id set team2_wickets = wickets;

-- checking whether win_by_runs/wickets columns matches the winning margin generated using the calculated innings score
select match_id, year(date), result_type, batting_team1, batting_team2, team1_runs, team1_wickets, team2_runs, team2_wickets, win_type, win_margin, if (team2_runs>=team1_runs,10 - team2_wickets, team1_runs- team2_runs) as win_margin_calc, (if(team2_runs>=team1_runs,10 - team2_wickets, team1_runs- team2_runs)) = win_margin as test from matches where result_type not in ('tie','no result', 'DL applied') order by date;
