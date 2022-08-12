# importing the libraries we will use throughtout this mission.

from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By

options = Options()
options.add_argument("--profile-directory=Default")
options.add_argument("--headless")
options.add_argument('--no-sandbox') 
options.add_argument('--disable-dev-shm-usage')        
options.add_argument('--disable-blink-features=AutomationControlled')
options.add_argument("start-maximized")
options.add_argument("--incognito")
options.add_argument("--disable-site-isolation-trials")
options.add_argument("user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36")

driver = webdriver.Chrome(service = Service(executable_path='C:/Users/armon/Downloads/chromedriver_win32/chromedriver.exe'), options=options)

from faker import Faker 
import pandas as pd
import numpy as np
import time
import csv 
import random
import mysql.connector



# first off let's type the small data ourselves. Like alliances names and cultivation powers.

cultivation_list = ["Demonic", "Shadow", "Light", "Poison", "Plants", "Darkness", "Wind", "Lightning", "Water", "Earth", "Physical Strength"
                    ,"Wisdom", "Souls", "Magic", "Sword", "Medicine", "Array", "forest", "Fire", "telekinesis", "Minds"]

alliance_list = ["Iron Brotherhood Alliance", "Beast Tamers Alliance", "Holy Lands of Flame Allinace",
             "Truth Seeking Alliance", "Heaven Trampling Alliance", "Godly Phoenix Alliance", "Demon Banishment Alliance"
            , "Death Masters Alliance", "Etheral light Alliance", "Northern Wall Alliance", "Central Heavenly Alliance", "Crimson Dragons Alliance"
            , "Shadow Vengeance Alliance", "Silent Night Alliance"]



# Now let's start scraping. First off let's get the names of sects. 

def get_sect_names():

    driver.get('https://www.fantasynamegenerators.com/wuxia-sect-names.php')
    time.sleep(3)
    final = []
    load_more = driver.find_element(By.XPATH, '//*[@id="nameGen"]/input')
  
    for _ in range(10):   # each loop gives us 10 names so 100 names is more than enough. We didnt choose a smaller number because sometimes there are duplicates, ew.
        time.sleep(2)
        result = driver.find_element(By.XPATH , '//*[@id="result"]').get_attribute("innerText").split('\n')
        for sect in result:
            if len(sect) > 0:
                sect_name = sect.split(' ')[0]
                final.append(sect_name)
    
        driver.execute_script("arguments[0].click();", load_more)
    driver.close()
    return final


sects_list = get_sect_names()
sects_list = list(dict.fromkeys(sects_list)) ## to get rid of duplicates

sects_backup = pd.DataFrame(sects_list)
sects_backup.to_csv('sects_backup.csv')


# We got sects outta the way, now for the names. 

global backup
backup = []


def get_citizen_names():

    final = []
    driver = webdriver.Chrome(service = Service(executable_path='C:/Users/armon/Downloads/chromedriver_win32/chromedriver.exe'), options=options)
    driver.get('https://blog.reedsy.com/character-name-generator/language/mandarin-chinese/')
    time.sleep(3)
    load_more = driver.find_element(By.XPATH, '//*[@value="Generate names"]')

    for _ in range(10000):
        time.sleep(2)
        result = driver.find_elements(By.XPATH, '//*[@id="names-container"]')
        for item in result:
            names = item.find_elements(By.TAG_NAME, "h3")
            time.sleep(2)
            for name in names:
                global backup
                time.sleep(1)
                ch_name = name.get_attribute("innerText")
                time.sleep(1)
                backup.append(ch_name)
                final.append(ch_name)
                time.sleep(1)
        driver.execute_script("arguments[0].click();", load_more)
    
    return final


# We used whatever we could gather in the backup list, because the function takes wayyyyyyyyyy too long. and after running for 7 hrs once, I thought it collected like 30k names but that website has a lot of duplicates and I ended up with like 8k. so yeah, we will use the backup list.

names1 = list(dict.fromkeys(backup))
names = pd.DataFrame(names1)
names.to_csv('names_backup.csv')  # Always build a habit of saving the data you gather if it's large, just in case you need some and you offline or something happened.


# We need more names so we will use faker library to extract romanized chinese names (pinyin)

fake = Faker("zh_CN")

faker_names = []

for _ in range(1000000):
    faker_names.append(fake.romanized_name())

fakes = list(dict.fromkeys(faker_names))

fakes1 = pd.DataFrame(fakes)
fakes1.to_csv('fakes_backup.csv')


# something I wanted to do as well, get actual chinese names and not romanized. But I kept pinyin for the people who prefer it and dont know how to read the Chinese characters.

chinese = []

for _ in range(1000000):
    chinese.append(fake.name())

chinese_names = list(dict.fromkeys(chinese))
chinese = pd.DataFrame(chinese_names)
chinese.to_csv('Chinese_names_backup.csv')


# Let's get our faker names and switch between the surname and given name

fake_pinyin = []

with open('fakes_backup.csv') as f:
    lines = [line.split(',') for line in f]
    for line in lines:
        full_name = line[1].split('\n')[0]
        split = full_name.split(' ')
        fake_pinyin.append(split[1] + " " + split[0])


# now extract the backup names in a list too.

backup_names = []

with open('names_backup.csv') as f:
    lines = [line.split(',') for line in f]
    for line in lines:
        full_name = line[1].split('\n')[0]
        backup_names.append(full_name)


# join together and make sure no duplicates 

pinyin_names = fake_pinyin + backup_names
complete_pinyin_names = list(dict.fromkeys(pinyin_names))



# Let's also get our chinese names nice and ready. This is not necessary since the function that generates them runs really fast and no need to bother with csv reading. But I did so because I love making my life hard.

complete_chinese_names = []

with open('Chinese_names_backup.csv') as f:
    lines = [line.split(',') for line in f]
    for line in lines:
        full_name = line[1].split('\n')[0]
        complete_chinese_names.append(full_name)

# seems like there is an encoding issue with reading chinese characters from csv files, but will pass since getting them through faker takes less than a minute.

# Create our database. 

db = mysql.connector.connect(host = "localhost", user = "root", password = "##########")

mycursor = db.cursor()

mycursor.execute("CREATE DATABASE WANHUI")

db = mysql.connector.connect(host = "localhost", user = "root", password = "##########", database = 'WANHUI')

# Let's start with the easiest table: alliances.

mycursor.execute("CREATE TABLE alliances (ID INT PRIMARY KEY AUTO_INCREMENT, alliance_name VARCHAR(100) NOT NULL) ")

vals  = ", ".join(f"('{alliance}')" for alliance in alliance_list)
mycursor.execute(f"INSERT INTO alliances (alliance_name) VALUES {vals}")
db.commit()

# Now let's continue with the sects table:

mycursor.execute("CREATE TABLE sects (ID INT PRIMARY KEY AUTO_INCREMENT, sect_name VARCHAR(100), alliance_id INT)")

vals = []
for sect in sects_list:
    vals.append((sect, random.randint(1,14)))

sql = "INSERT INTO sects (sect_name, alliance_id) VALUES (%s, %s)"

mycursor.executemany(sql, vals)
db.commit()

mycursor.execute("CREATE TABLE inventory (ID INT PRIMARY KEY AUTO_INCREMENT, sect_id INT, swords INT, arrows INT, poison INT, daggers INT, ships INT, SS_Rated_weapons INT )")

vals = []
i = 1

for sect in sects_list:
    vals.append((i, random.randint(0,5000), random.randint(0,10000), random.randint(0,1000), random.randint(0,1000) , random.randint(0,50) , random.randint(0,10)))
    i = i+1

sql = "INSERT INTO inventory (sect_id, swords, arrows, poison, daggers, ships, SS_Rated_weapons) VALUES (%s, %s, %s, %s, %s, %s, %s)"

mycursor.executemany(sql, vals)
db.commit()


# Now for the last table, citizens.

sql = """CREATE TABLE citizens(
    ID INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100),
    age INT,
    Gender ENUM('F', 'M'),
    cultivation VARCHAR(100),
    power_rank INT,
    isRouge ENUM('Yes', 'No'),
    sect_id INT)"""

mycursor.execute(sql)

vals = []

weights = [0.99, 0.01]

ranks = ['1','2','3','4','5','6','7','8','9']
ranks_weight  = [0.25, 0.15, 0.20, 0.15, 0.10, 0.05, 0.06, 0.03, 0.01 ]

for name in complete_pinyin_names:
    vals.append((name, random.randint(15, 77), random.choice(['M', 'F']), random.choice(cultivation_list), np.random.choice(ranks, p=ranks_weight), np.random.choice(['No', 'Yes'], p=weights), random.randint(1,30)))

sql = "INSERT INTO citizens (full_name, age, Gender, cultivation, power_rank, isRouge, sect_id) VALUES (%s, %s, %s, %s, %s, %s, %s)"

mycursor.executemany(sql, vals)
db.commit()


# For this last step, I will also include an extra citizens table with the chinese names. 

sql = """CREATE TABLE citizens_CH(
    ID INT PRIMARY KEY AUTO_INCREMENT,
    full_name VARCHAR(100),
    age INT,
    Gender ENUM('F', 'M'),
    cultivation VARCHAR(100),
    power_rank INT,
    isRouge ENUM('Yes', 'No'),
    sect_id INT)"""

mycursor.execute(sql)

vals = []

weights = [0.99, 0.01]

ranks = ['1','2','3','4','5','6','7','8','9']
ranks_weight  = [0.25, 0.15, 0.20, 0.15, 0.10, 0.05, 0.06, 0.03, 0.01 ]

for name in chinese_names:
    vals.append((name, random.randint(15, 77), random.choice(['M', 'F']), random.choice(cultivation_list), np.random.choice(ranks, p=ranks_weight), np.random.choice(['No', 'Yes'], p=weights), random.randint(1,68)))

sql = "INSERT INTO citizens_CH (full_name, age, Gender, cultivation, power_rank, isRouge, sect_id) VALUES (%s, %s, %s, %s, %s, %s, %s)"

mycursor.executemany(sql, vals)
db.commit()


################################# THE END ######################################