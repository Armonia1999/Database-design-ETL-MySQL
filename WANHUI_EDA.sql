-- -------------------------------------------------------------------------------------------------------
-- --------------------------------------------- WANHUI EDA ----------------------------------------------
-- -------------------------------------------------------------------------------------------------------

USE WANHUI; 

-- first off let's get a sneak peek at our tables:

SELECT * FROM citizens LIMIT 20;
SELECT * FROM sects LIMIT 20;
SELECT * FROM inventory LIMIT 20;
SELECT * FROM alliances LIMIT 20;
SELECT * FROM citizens_CH LIMIT 20;

-- The shape of our data:

SELECT COUNT(*) AS num_rows FROM citizens;
SELECT COUNT(*) AS num_columns FROM information_schema.columns WHERE TABLE_NAME = 'citizens';

SELECT COUNT(*) AS num_rows FROM sects;
SELECT COUNT(*) AS num_columns FROM information_schema.columns WHERE TABLE_NAME = 'sects';

SELECT COUNT(*) AS num_rows FROM inventory;
SELECT COUNT(*) AS num_columns FROM information_schema.columns WHERE TABLE_NAME = 'inventory';

SELECT COUNT(*) AS num_rows FROM alliances;
SELECT COUNT(*) AS num_columns FROM information_schema.columns WHERE TABLE_NAME = 'alliances';

SELECT COUNT(*) AS num_rows FROM citizens_CH;
SELECT COUNT(*) AS num_columns FROM information_schema.columns WHERE TABLE_NAME = 'citizens_CH';

-- Normally here we would be checking if there are nulls or empty spaces, but since we built this database from scratch and validated our data using python
-- we wont do it this time.

-- Before continuing with our exploration, I would like to change something:
-- splitting the full_name column in the tables citizens and citizens_ch to two columns: given_name and surname.

SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(full_name, ' ', 1), ' ', -1) AS surname,
       SUBSTRING_INDEX(SUBSTRING_INDEX(full_name, ' ', 2), ' ', -1) AS given_name
FROM   citizens;

SELECT full_name,
	   LEFT(full_name,1) AS SurName,
       SUBSTRING(full_name,2,9999) AS GivenName
FROM citizens_CH;


-- after we verified that we can split the column successfully, let's assign them to their respective tables.

-- add the new columns we need to the tables:

ALTER TABLE citizens ADD surname VARCHAR(250) DEFAULT '' AFTER full_name;
ALTER TABLE citizens ADD given_name VARCHAR(250) DEFAULT '' AFTER surname;

ALTER TABLE citizens_CH ADD surname VARCHAR(250) DEFAULT '' AFTER full_name;
ALTER TABLE citizens_CH ADD given_name VARCHAR(250) DEFAULT '' AFTER surname;

-- populate them with the data :

UPDATE citizens SET
surname = SUBSTRING_INDEX(SUBSTRING_INDEX(full_name, ' ', 1), ' ', -1),
given_name = SUBSTRING_INDEX(SUBSTRING_INDEX(full_name, ' ', 2), ' ', -1)
WHERE ID > 0;  # to bypass the safe mode error.

UPDATE citizens_CH SET
surname = LEFT(full_name,1),
given_name = SUBSTRING(full_name,2,9999)
WHERE ID > 0;

-- We fixed that ! Now on with our EDA. Let's see if we have duplicates in names ( we don't... but for the sake of it): 
 
SELECT COUNT(full_name) AS total, COUNT( DISTINCT full_name) AS unique_names FROM citizens; 

SELECT COUNT(full_name) AS total, COUNT( DISTINCT full_name) AS unique_names FROM citizens_CH; 

-- Q1: What is the count of male and female martial artists ?

SELECT gender , COUNT(*) FROM citizens GROUP BY 1;

SELECT gender , COUNT(*) FROM citizens_CH GROUP BY 1;

-- Q2: How many alliances and sects we have? 

SELECT COUNT(DISTINCT alliance_name) AS alliances_number FROM alliances;
SELECT COUNT(DISTINCT alliance_id) AS unique_alliances FROM sects WHERE ID < 31;
SELECT COUNT(DISTINCT alliance_id) AS unique_alliances FROM sects WHERE ID < 69;

SELECT COUNT(DISTINCT sect_id) AS sect_number FROM citizens;

SELECT COUNT(DISTINCT sect_id) AS sect_number FROM citizens_CH;

-- Q3: What is the average age in different sects ?

SELECT sect_name, AVG(age) AS average_age 
FROM citizens 
JOIN sects ON citizens.sect_id = sects.ID
GROUP BY 1 
ORDER BY 2 DESC;

SELECT sect_name, AVG(age) AS average_age 
FROM citizens_CH 
JOIN sects ON citizens_CH.sect_id = sects.ID
GROUP BY 1 
ORDER BY 2 DESC;

-- Q4: Same as question three but check average age also across genders:

SELECT sect_name, gender, AVG(age) AS average_age 
FROM citizens 
JOIN sects ON citizens.sect_id = sects.ID
GROUP BY 1, 2
ORDER BY 1,2,3 DESC;

SELECT sect_name, gender, AVG(age) AS average_age 
FROM citizens_CH 
JOIN sects ON citizens_CH.sect_id = sects.ID
GROUP BY 1, 2
ORDER BY 1, 2,3 DESC;

-- Q5 : The count of martial artists by sects:

SELECT sect_name, COUNT(*) AS num_followers
FROM citizens
JOIN sects ON citizens.sect_id = sects.ID
GROUP BY 1 ORDER BY 2 DESC;

SELECT sect_name, COUNT(*) AS num_followers
FROM citizens_CH
JOIN sects ON citizens_CH.sect_id = sects.ID
GROUP BY 1 ORDER BY 2 DESC;

-- Q6: which alliance has the most number of people in it and who has the least ?

SELECT alliance_name, COUNT(full_name) AS total_followers
FROM citizens
JOIN sects ON citizens.sect_id = sects.ID
JOIN alliances ON sects.alliance_id = alliances.ID
GROUP BY 1 ORDER BY 2 DESC;

SELECT alliance_name, COUNT(full_name) AS total_followers
FROM citizens_CH
JOIN sects ON citizens_CH.sect_id = sects.ID
JOIN alliances ON sects.alliance_id = alliances.ID
GROUP BY 1 ORDER BY 2 DESC;

-- Q7: Which sect has the highest number of SS Rated weapons?

SELECT sect_name, SS_Rated_weapons
FROM inventory
JOIN sects ON inventory.sect_id  = sects.ID
ORDER BY 2 DESC;

-- Q8: Which surname is the most common in all of Wanhui ?

SELECT surname, COUNT(*) FROM citizens GROUP BY 1 ORDER BY 2 DESC LIMIT 1;

SELECT surname, COUNT(*) FROM citizens_CH GROUP BY 1 ORDER BY 2 DESC LIMIT 1;

-- Q9: What cultivation is the most prevalent ?

SELECT cultivation, COUNT(*) FROM citizens GROUP BY 1 ORDER BY 2 DESC;

SELECT cultivation, COUNT(*) FROM citizens_CH GROUP BY 1 ORDER BY 2 DESC;

-- Q10: Which sect has the most number of rouge martial artists:

SELECT sect_name, COUNT(*) num_rouge
FROM citizens 
JOIN sects ON citizens.sect_id = sects.ID
WHERE isRouge = 'Yes'
GROUP BY 1 ORDER BY 2 DESC;

SELECT sect_name, COUNT(*) num_rouge
FROM citizens_CH
JOIN sects ON citizens_CH.sect_id = sects.ID
WHERE isRouge = 'Yes'
GROUP BY 1 ORDER BY 2 DESC;

-- Q11: What is the cultivation of most of who are rouge ? 

SELECT cultivation, COUNT(*) AS rouge_practicioners
FROM citizens WHERE isRouge='Yes' GROUP BY 1 ORDER BY 2 DESC;

SELECT cultivation, COUNT(*) AS rouge_practicioners
FROM citizens_CH WHERE isRouge='Yes' GROUP BY 1 ORDER BY 2 DESC;

-- Q12: which sect has the most number of advanced martial artists (ranks 7-9):

SELECT sect_name , COUNT(*) AS advanced_ranks
FROM citizens 
JOIN sects ON citizens.sect_id = sects.ID
WHERE citizens.power_rank BETWEEN 7 AND 9
GROUP BY 1 ORDER BY 2 DESC;

SELECT sect_name , COUNT(*) AS advanced_ranks
FROM citizens_CH 
JOIN sects ON citizens_CH.sect_id = sects.ID
WHERE citizens_CH.power_rank BETWEEN 7 AND 9
GROUP BY 1 ORDER BY 2 DESC;

-- We have been contacted By Chen Cheng and he wants us to change something. To select the a perosn with the rank 9, 
-- if more than one exists, choose the oldest, change their rank to 10 and assign them as sect master.

WITH candidates AS (
  SELECT c.sect_id, c.full_name, c.age, ROW_NUMBER() OVER (PARTITION BY sect_id ORDER BY age DESC) AS rn
  FROM citizens AS c WHERE power_rank = 9
)
SELECT * FROM candidates WHERE rn = 1;

-- Now, something will go wrong here. The table sects have alllll of the sects we scraped , 98 sects to be precise. 
-- If we try to add sect_master from the table citizens to the table sects we would only give names for the first 30 sects ! 
-- And also the names won't be valid if we link citizens_CH and sects since they are the not the same names, or even language, or anything. 
-- Hmm, so what shall we do?... Create a new table sects_CH ! We will simply copy it

CREATE TABLE sects_CH AS SELECT * FROM sects;
SELECT * FROM sects_CH;

-- Now let's add the columns to our tables:

ALTER TABLE sects ADD sect_master VARCHAR(250) DEFAULT '' AFTER sect_name;

ALTER TABLE sects_CH ADD sect_master VARCHAR(250) DEFAULT '' AFTER sect_name;

-- We also want the sect_master ID to be included:

ALTER TABLE sects ADD sect_master_id INT DEFAULT 0 AFTER sect_master;

ALTER TABLE sects_CH ADD sect_master_id INT DEFAULT 0 AFTER sect_master;

-- Now let's start populating these columns.

WITH candidates AS (
  SELECT c.sect_id, c.full_name, c.age,c.ID, ROW_NUMBER() OVER (PARTITION BY sect_id ORDER BY age DESC) AS rn
  FROM citizens AS c WHERE power_rank = 9
)

UPDATE sects INNER JOIN( SELECT full_name, sect_id FROM candidates  WHERE rn=1) AS result ON sects.ID = result.sect_id SET sects.sect_master = result.full_name;
UPDATE sects INNER JOIN(SELECT sect_id, ID FROM candidates  WHERE rn=1) AS result ON sects.ID = result.sect_id SET sects.sect_master_id = result.ID;

-- Let's do same for citizens_CH: 

SET SQL_SAFE_UPDATES = 0;

WITH candidates AS (
  SELECT c.sect_id, c.full_name, c.age,c.ID, ROW_NUMBER() OVER (PARTITION BY sect_id ORDER BY age DESC) AS rn
  FROM citizens_CH AS c WHERE power_rank = 9
)

UPDATE sects_CH INNER JOIN( SELECT full_name, sect_id FROM candidates WHERE rn=1) AS result
ON sects_CH.ID = result.sect_id SET sects_CH.sect_master = result.full_name;

UPDATE sects_CH INNER JOIN(SELECT sect_id, ID FROM candidates  WHERE rn=1) AS result
ON sects_CH.ID = result.sect_id SET sects_CH.sect_master_id = result.ID;

SET SQL_SAFE_UPDATES = 1;

-- Let's see if some of the sect_masters are rouge (either left the sect or are basically traitors) since we forogt to mention that earlier :/
-- Should've added that condition to the candidates CTE. 

SELECT COUNT(*) FROM citizens 
JOIN sects ON citizens.ID = sects.sect_master_id 
WHERE isRouge = 'Yes';  

SELECT COUNT(*) FROM citizens_CH 
JOIN sects_CH ON citizens_CH.ID = sects_CH.sect_master_id 
WHERE isRouge = 'Yes'; 

-- AH HAH ! There is a rouge sect master in the citizens_CH table. Let's keep this a secret for now. Not paid enough to snitch. 
-- But let's see who are they for ourselves since we love drama :

SELECT full_name, age, gender, cultivation, power_rank, sect_name FROM citizens_CH 
JOIN sects_CH ON citizens_CH.ID = sects_CH.sect_master_id 
WHERE isRouge = 'Yes'; 

-- What's left now is to change their ranks to 10 !

UPDATE citizens
SET power_rank = 10 WHERE ID IN (SELECT sect_master_ID FROM sects);

UPDATE citizens_CH
SET power_rank = 10 WHERE ID IN (SELECT sect_master_ID FROM sects_CH);

-- Ok now we got that outta the way ~ 



-- !!!! BREAKING NEWS !!!! 

-- All rouge martial artists joined hands and chose to follow a mysterious man who is from another country 
-- The Supreme Ruler we work for asked us to make the necessary adjustments to our database. 
-- It's rumored that this man's name is 'Armonia', 23 years old with 'Demonic' cultivation probably.
-- He is announcing that this new sect shall be called 'Necro' because of his ability of controlling the dead
-- So we should add that sect to our tables, and also add this suspicious man as a "citizen". 
 
-- Let's add him as a citizen first:

INSERT INTO citizens(full_name, surname, given_name, age, Gender, cultivation, power_rank, isRouge, sect_id) 
VALUES('Armonia', '', '', 23, 'M', 'Necromancy', 10, 'No', 99); # we already have 98 sects so his will be the 99th. 

INSERT INTO sects(sect_name, sect_master, sect_master_id)
VALUES('Necro', 'Armonia', 9980);

-- Ok so we added him and the sect to the database. Let's make all the rouge people follow his sect.

SET SQL_SAFE_UPDATES = 0;
UPDATE citizens SET sect_id = 99 WHERE isRouge='Yes';

-- hmm should we give them some weapons ?.... yip

INSERT INTO inventory(sect_id, swords, arrows, poison, daggers, ships, SS_Rated_weapons)
VALUES(99, 500, 723, 2, 125, 1, 2);

-- Let's make an alliance and add only his sect to it.

INSERT INTO alliances(alliance_name) VALUES ('SOLO');

UPDATE sects SET alliance_id = 15 WHERE ID = 99;
SET SQL_SAFE_UPDATES = 1;

-- Ok we are done with updating citizens, you can do the same for citizens_CH by yourself. 
-- Be careful though, we already discovered there is a traitor among the sect leaders there and we dont wanna give him off
-- Make sure you dont change his sect_id and leave him be. 
-- This is it for now, next time we might start planning wars between the sects and 'Necro' :) 
-- But we leaving that for another day, when Chen Cheng pays us again ~

-- LAST STEP: load all the data we need into one table and export it to a CSV file so we can visualize it later. 

SELECT c.ID, c.full_name, c.surname,c.sect_id, c.age, c.gender, c.cultivation, c.power_rank, c.isRouge, s.sect_name, a.alliance_name
FROM citizens c
JOIN sects s ON c.sect_id = s.ID
JOIN alliances a ON s.alliance_id = a.ID
INTO OUTFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Wanhui.txt'
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n';