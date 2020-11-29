var express = require('express');
var router = express.Router();
var path = require('path');

var Rounds = require('../models/rounds');

router.get('/', function(req, res){
  res.sendFile(path.join(__dirname, '../dist/index.html'));
});

router.get('/api/rounds', function(req, res){
  var user = req.query.user;
  Rounds.getRounds(user)
  .then(function(result) {
    res.json({rounds: result});
  })
  .catch(function(error) {
    console.log('index.js - getRounds GET - error ' + error);
    res.json({err: error + ''});
  });
});

router.get('/api/input-rounds', function(req, res){
  Promise.all([
    Rounds.getPlayers(),
    Rounds.getClubs()
  ])
  .then(function(result) {
    res.json({players: result[0], clubs: result[1]});
  })
  .catch(function(error) {
    console.log('index.js - input-rounds GET - error ' + error);
    res.json({err: error + ''});
  });
});

router.post('/api/input-rounds', function(req, res){
  var round = req.body;
  Rounds.inputRounds(round)
  .then(function(result) {
    res.json({success: result});
  })
  .catch(function(error) {
    console.log('index.js - inputRounds POST - err ' + error);
    res.json({err: error + ''});
  });
});

module.exports = router;
