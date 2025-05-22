# IPL Analytics Project - Analyzing the miracles, fails and scams of the Indian Premier League

**All the data cleaning, wrangling and EDA has been done solely using MySQL. To generate columns/ changes that would require modifying majority of the table rows, Python was used instead, because of its procedural nature.**

### Source data:
Source          |                            Link                          |        Description
----------------|----------------------------------------------------------|-----------------------------
Kaggle | <a href='https://www.kaggle.com/nowke9/ipldata'>IPL dataset -1</a> | Ball-by-ball data for each match from IPL 2008 to 2019
Kaggle | <a href='https://www.kaggle.com/patrickb1912/ipl-complete-dataset-20082020'>IPL dataset -2</a> | Ball-by-ball data for each match from IPL 2020
Cricsheet | <a href='https://cricsheet.org/matches/'>IPL dataset -3</a> | Match day squads for each match from IPL 2008 to 2020
ESPNcricinfo | <a href='https://cricsheet.org/matches/'>IPL Season Squads</a> | Player and team backgrounds for each season
MoneyBall | <a href='https://cricsheet.org/matches/'>IPL Player Salaries</a> | Player salaries and team budgets for each season

### FUTURE OBJECTIVES: 
- Power BI (or whichever BI tool that interests me then) will be used for visualization. 
- A FAST API is also in the plan for ensuring public access to the data. 
- Pitch report on the specific match day
- Correlating with performances on the international circuit and other famous T20 leagues
- Ball by ball pitching and hitting direction coordinates 
- Fantasy points for each player for each match based on stage of innings and team's situation
- Team Rivalries
- Player Rivalries
- Top Young Prospects for each season
- Top 50/100 players for each player role

### NEXT COMMIT OBJECTIVES:
- Views for batsmen performances in various stages of innings
- Ball by ball pitching and hitting direction coordinates 
- Fantasy points for each player for each match based on stage of innings and team's situation


### Errors remaining:
- (runs_on_dismissal, overs_on_dismissal) and (runs_on_arrival, overs_on_arrival) do not match because of addition of runs on the 1st ball a new batsman faces
- Day/ Night may not be that accurate, need to verify
- Player info and salary may need verification
- Very minor errors in Net Run Rate calculated, especially for DLS applied matches  

### Project Flow:

1. "1 - import and format base tables.sql" :
   - Imported *matches.csv* and *deliveries.csv* from *IPL dataset -1* and reformatted the match_ids to match the chronological order
   - Reformatting the matches.csv and deliveries.csv to match the format of the csv files from *IPL dataset -2*, from which 2020 data was only retrieved
   - Renaming some duplicate fields in **Matches** table
   - Creation of **Venues** and **Teams** table to use venue_ids and short_names for each match and team respectively
   - Introduced Home/ Away/ Neutral/ Semifinals/ Finals/ Eliminators values in **Matches** after finding home venues for each team in each season

2. "2 - data cleaning and addition.sql" :
   - Solved the issues of overs with duplicate or missing balls in **Deliveries** table. Included many key (fall of wicket) instances not recorded in the dataset 
   - Solved cases where batsmen changed suddenly between 2 balls (due to getting retired hurt), by using the 3rd step Python script
   - **MAJOR ISSUE** in *deliveries.csv* was that extras were included in batsman_runs as well as extra_runs, thus getting counted twice in total_runs for the seasons 2018 and 2019
   - Updated **Matches** table with each inning's score
   
3. "recreate deliveries table.py" : 
   - Regenerated *deliveries.csv* with added columns for running team scores, and batsman & non-striker runs and balls
   - Renamed some duplicate player names for each instance occuring in the old *deliveries.csv* (found these changes after the creation of **Match Batsman Scorecards** table in the 4th step, where teams with 11+ members were found in 80+ cases)
   - Found retired hurt cases (where batsmen changed suddenly between 2 balls) of the 2nd step
   - **NOTE:** Generating and updating running team, batsman and non-striker runs and balls using SQL (Stored procedures and/or Window functions and/or Cursor/Loops) (min. 4 hours) would have taken more time compared to Python (~10 seconds)

4. "3 - post-py scorecards tables.sql"
   - Created **Match_bowler_scorecards** table with stats for each bowler's each innings
   - Created **Match_batsman_scorecards** table with stats for each batsman's each innings. Updated with match day squads using the 5th step Python script
   - Created **Match_over_scorecards** table with stats for each over in each innings

5. "match_squads.py"
   - Inserted the batsamn that didn't get a chance to bat into **Match_batsman_scorecards** table, thus also completing the Playing XI of both teams for each match using *IPL dataset -3*
   - **NOTE:** Each match had a seperate JSON file in *IPL dataset -3*, which would have made it very cumbersome to import into a table and then update the **Match_batsman_scorecards** table. There were also some cases of player names not matching which was easier to deal with in Python.  

6. "0 - players-salaries.py"
   - Scraped *MoneyBall* to generate the *IPL Player Salaries* dataset
   - Had some missing/ name mismatching values

7. "0 - squad list espn.py"
   - Scraped *ESPNCricInfo* to generate the *IPL Season Squads* dataset
   - Had some missing/ name mismatching values

8. "3 - player-names-match.py"
   - Compared and matched the names and seasons played of each player from the **Match_batsman_scorecards** table to the values available in *IPL Player Salaries* & *IPL Season Squads* datasets
   - Inserted the relevant data into the subsequent tables 

9. "4 - post-py player info tables.sql"
   - Created of **Players** (basic player background), **No_Matches_Played** (players that never got a chance to play a single match in IPL after getting drafted) and **Season_Player_info** (Player info for each season) tables
   - Created using the self-generated *IPL Player Salaries* and *IPL Season Squads* datasets
   - **MAJOR ISSUE:** Matching the names from the **Match_batsman_scorecards** table, and *IPL Player Salaries* & *IPL Season Squads* datasets was the biggest hurdle. Solved it using 8th step Python script

10. "5 - points table, powerplay and death-overs tables.sql"
   - Created **Points Table** with Net Run Rates for each teams, and **Detailed Matches** tables
   - Created special views for player performances in the powerplay, middle and death overs