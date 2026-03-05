


CREATE TABLE goals (
    goal_id VARCHAR(10),
    match_id VARCHAR(10),
    pid VARCHAR(10),
    duration INTEGER,
    assist VARCHAR(10),
    goal_desc VARCHAR(50)
);

COPY goals(goal_id, match_id, pid, duration, assist, goal_desc)
FROM 'D:\Project\Cuvett dataset\goals.csv'
DELIMITER ','
CSV HEADER
NULL '';

CREATE TABLE matches_temp (
    match_id VARCHAR(10),
    season VARCHAR(20),
    match_date VARCHAR(20),
    home_team VARCHAR(50),
    away_team VARCHAR(50),
    stadium VARCHAR(100),
    home_team_score INTEGER,
    away_team_score INTEGER,
    penalty_shoot_out INTEGER,
    attendance INTEGER
);


COPY matches_temp
FROM 'D:\Project\Cuvett dataset\Matches.csv'
DELIMITER ','
CSV HEADER
NULL '';


INSERT INTO matches_temp
SELECT 
    match_id,
    season,
    CASE 
        WHEN match_date LIKE '%-%-%-20__' THEN TO_DATE(match_date, 'DD-MM-YYYY')
        WHEN match_date LIKE '%-%-__' THEN TO_DATE(match_date, 'DD-Mon-YY')
        ELSE NULL
    END,
    home_team,
    away_team,
    stadium,
    home_team_score,
    away_team_score,
    penalty_shoot_out,
    attendance
FROM matches_temp;

select * from matches_temp limit 10;

CREATE TABLE players_temp (
    player_id VARCHAR(10),
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    nationality VARCHAR(50),
    dob VARCHAR(20),
    team VARCHAR(50),
    jersey_number INTEGER,
    position VARCHAR(30),
    height INTEGER,
    weight INTEGER,
    foot VARCHAR(5)
);

COPY players_temp
FROM 'D:\Project\Cuvett dataset\Players.csv'
DELIMITER ','
CSV HEADER
NULL '';

Select * from players_temp limit 15;



CREATE TABLE stadium (
    name VARCHAR(100),
    city VARCHAR(50),
    country VARCHAR(50),
    capacity INTEGER
);


COPY stadium(name, city, country, capacity)
FROM 'D:\Project\Cuvett dataset\Stadiums.csv'
DELIMITER ','
CSV HEADER
NULL ''
ENCODING 'UTF8';

SELECT * FROM stadium LIMIT 10;


CREATE TABLE teams (
    team_name VARCHAR(100) PRIMARY KEY,
    country VARCHAR(50),
    home_stadium VARCHAR(100)
);

COPY teams(team_name, country, home_stadium)
FROM 'D:\Project\Cuvett dataset\Teams.csv'
DELIMITER ','
CSV HEADER
NULL ''
ENCODING 'UTF8';

SELECT * FROM matches_temp LIMIT 10;

--Q1.1.	Which player scored the most goals in a each season?--
SELECT m.season,
       p.player_id,
       p.first_name,
       p.last_name,
       COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches_temp m
    ON g.match_id = m.match_id
JOIN players_temp p
    ON g.pid = p.player_id
GROUP BY m.season, p.player_id, p.first_name, p.last_name;


--Q2.2.	How many goals did each player score in a given season?--
SELECT 
    m.season,
    p.player_id,
    p.first_name,
    p.last_name,
    COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches_temp m
    ON g.match_id = m.match_id
JOIN players_temp p
    ON g.pid = p.player_id
GROUP BY 
    m.season,
    p.player_id,
    p.first_name,
    p.last_name
ORDER BY 
    m.season,
    total_goals DESC;


--Q3.What is the total number of goals scored in ‘mt403’ match?--	
SELECT COUNT(goal_id) AS total_goals
FROM goals
WHERE match_id = 'mt403';

--Q4.Which player assisted the most goals in a each season?--
SELECT t1.season,
       t1.first_name,
       t1.last_name,
       t1.total_assists
FROM (
    SELECT m.season,
           p.player_id,
           p.first_name,
           p.last_name,
           COUNT(g.goal_id) AS total_assists
    FROM goals g
    JOIN matches_temp m
        ON g.match_id = m.match_id
    JOIN players_temp p
        ON g.assist = p.player_id
    WHERE g.assist IS NOT NULL
    GROUP BY m.season, p.player_id, p.first_name, p.last_name
) t1
JOIN (
    SELECT season,
           MAX(assist_count) AS max_assists
    FROM (
        SELECT m.season,
               COUNT(g.goal_id) AS assist_count
        FROM goals g
        JOIN matches_temp m
            ON g.match_id = m.match_id
        WHERE g.assist IS NOT NULL
        GROUP BY m.season, g.assist
    ) t2
    GROUP BY season
) t3
ON t1.season = t3.season
AND t1.total_assists = t3.max_assists;

--Q5.Which players have scored goals in more than 10 matches?--
SELECT 
    p.player_id,
    p.first_name,
    p.last_name,
    COUNT(DISTINCT g.match_id) AS matches_scored
FROM goals g
JOIN players_temp p
    ON g.pid = p.player_id
GROUP BY 
    p.player_id,
    p.first_name,
    p.last_name
HAVING COUNT(DISTINCT g.match_id) > 10
ORDER BY matches_scored DESC;

--Q6.What is the average number of goals scored per match in a given season?
SELECT 
    m.season,
    AVG(goal_count) AS avg_goals_per_match
FROM (
        SELECT 
            match_id,
            COUNT(goal_id) AS goal_count
        FROM goals
        GROUP BY match_id
     ) g
JOIN matches_temp m 
ON g.match_id = m.match_id
GROUP BY m.season;

--Q.7 Which team scored the most goals in the all seasons?
SELECT 
    m.season,
    Sum(goal_count) AS av_goals_per_match
FROM (
        SELECT 
            match_id,
            COUNT(goal_id) AS goal_count
        FROM goals
        GROUP BY match_id
     ) g
JOIN matches_temp m 
ON g.match_id = m.match_id
GROUP BY m.season;


--Q.8 Which team scored the most goals in the all seasons?
SELECT 
    t.team_name,
    COUNT(g.goal_id) AS total_goals
FROM goals g
JOIN matches_temp m
ON g.match_id = m.match_id
JOIN teams t
ON t.team_name = m.home_team 
   OR t.team_name = m.away_team
GROUP BY t.team_name
ORDER BY total_goals DESC
LIMIT 1;

--Q.9 Which stadium hosted the most goals scored in a single season?
SELECT season, stadium, total_goals
FROM (
    SELECT 
        m.season,
        m.stadium,
        COUNT(g.goal_id) AS total_goals,
        RANK() OVER(PARTITION BY m.season ORDER BY COUNT(g.goal_id) DESC) AS rnk
    FROM goals g
    JOIN matches_temp m
    ON g.match_id = m.match_id
    GROUP BY m.season, m.stadium
) t
WHERE rnk = 1;

--Q.10 What was the highest-scoring match in a particular season?
SELECT season, match_id, home_team, away_team, total_goals
FROM (
    SELECT 
        m.season,
        m.match_id,
        m.home_team,
        m.away_team,
        COUNT(g.goal_id) AS total_goals,
        RANK() OVER(PARTITION BY m.season ORDER BY COUNT(g.goal_id) DESC) AS rnk
    FROM matches_temp m
    LEFT JOIN goals g
    ON m.match_id = g.match_id
    GROUP BY m.season, m.match_id, m.home_team, m.away_team
) t
WHERE rnk = 1;
	   
	   


