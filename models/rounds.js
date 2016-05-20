var pg = require('pg');
var config = require('../config');
var path = require('path');

pg.defaults.ssl = true;
var conString = process.env.DATABASE_URL;

function handleError(err, cb) {
  if(!err) return false;

  if(typeof client !== 'undefined' && client){
    done(client);
  }
  cb(err);
  return true;
}  

function getRounds(user, cb){
  pg.connect(conString, function(err, client, done) {      
    if(handleError(err, cb)) return;
    client.query('SELECT * FROM get_rounds($1)', [user], function(err, result) {
      if(handleError(err, cb)) return;
      // convert rounds from db table format to json
      var dbRound, round, course, player, score;
      var playerCount = 1;
      var rounds = [];
      var isNewRound = true;
      var isNewCourse = true;
      var isNewPlayer = true;
      for (var i = 0; i < result.rows.length; i++){
        dbRound = result.rows[i];

        if (isNewRound) {
          if (i != 0) {
            // store previous round
            score.player = player;
            score.totalScore = score.totalStrokes - course.totalPar;
            course.scores.push(score);
            round.courses.push(course);
            rounds.push(round);
            playerCount = 1;
          }
          round = {};
          round.date = dbRound.round_date.toDateString();
          round.club = dbRound.club;
          round.courses = [];
        } 
        
        if (isNewPlayer) {
          if (i != 0 && !isNewRound) {
            // store previous player
            score.player = player;
            score.totalScore = score.totalStrokes - course.totalPar;
            course.scores.push(score);
            playerCount++;
          }
          player = dbRound.player;
          score = {};
          score.totalStrokes = 0;
          score.strokes = [];
        }

        if (isNewCourse) {
          if (i != 0 && !isNewRound) {
            // store previous course
            round.courses.push(course);
            playerCount = 1;
          }
          course = {};
          course.name = dbRound.course;
          course.tees = dbRound.tees;
          course.holes = [];
          course.numHoles = 0;
          course.yards = [];
          course.totalYards = 0;
          course.pars = [];
          course.totalPar = 0;
          course.scores = [];
        }

        // only update course info for first player of course
        if (playerCount == 1) {
          course.holes.push(dbRound.hole);
          course.numHoles++;
          course.yards.push(dbRound.yards);
          course.totalYards += dbRound.yards;
          course.pars.push(dbRound.par);
          course.totalPar += dbRound.par;
        }
        
        score.strokes.push(dbRound.strokes);
        score.totalStrokes += dbRound.strokes;

        if (i != result.rows.length - 1) {
          nextDbRound = result.rows[i + 1];
          isNewRound = dbRound.round_id != nextDbRound.round_id;
          isNewCourse = dbRound.round_course_id != nextDbRound.round_course_id;
          isNewPlayer = dbRound.player != nextDbRound.player || isNewCourse;
        }
      }

      if (result.rows.length > 0) {
        score.player = player;
        score.totalScore = score.totalStrokes - course.totalPar;
        course.scores.push(score);
        round.courses.push(course);
        rounds.push(round);
      }
        
      done();
      
      cb(null, rounds);
    });
  });
}

function inputRounds(newRound, cb){
  // convert input round from json to format of db function's params
  var dbRound = {};
  dbRound.roundDate = newRound.date;
  dbRound.club = newRound.club;
  dbRound.players = newRound.players;
  dbRound.courses = [];
  dbRound.tees = [];
  dbRound.holes = [];
  dbRound.strokes = [];
  newRound.courses.forEach(function(course) {
        dbRound.courses.push(course.name);
        dbRound.tees.push(course.tees);
        dbRound.holes.push(course.holes);
        dbRound.strokes.push(course.strokes);
  });
  
  pg.connect(conString, function(err, client, done) {
    if(handleError(err, cb)) return;
    client.query(
      'SELECT insert_rounds($1,$2,$3,$4,$5,$6,$7)', 
      [dbRound.roundDate, dbRound.club, dbRound.players, dbRound.courses, dbRound.tees, dbRound.holes, dbRound.strokes], 
      function(err, result) {
        if(handleError(err, cb)) return;
        var success = result.rows[0].insert_rounds;
        done();
        cb(null, success);
    });
  });
}

var Rounds = {'getRounds': getRounds, 'inputRounds': inputRounds};

module.exports = Rounds;
