# BirdieStats
Golf stat-tracking website: 
* NodeJS server
* VueJS front-end
* PostgreSQL db 

###Current Features:
* Input scores for a round 
* View scores for all rounds

###COMING SOON:
* Mobile App
* Stats - Handicap, Top 3 Lowest Scores, Avg. Score on Par 3s, ... 
* Swagger API

###Install: 
1. Download [PostgreSQL](http://www.enterprisedb.com/products-services-training/pgdownload#windows)
  1. Open pgAdmin program
  2. Create new database called birdie-stats 
  3. Open SQL Editor 
  4. Copy and paste code from [create_script.sql](https://github.com/MichaelViveros/BirdieStats/tree/master/models/db/create_script.sql) and execute it 
2. Download [NodeJS](https://nodejs.org/en/download/) 
  1. Install dependencies with "npm install" command in BirdieStats directory
3. Run server with "node app.js" command and go to [http://localhost:3000/](http://localhost:3000/)
