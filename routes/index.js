var express = require('express');
var router = express.Router();
var path = require('path');

var Rounds = require('../models/rounds');

router.get('/', function(req, res){
  res.sendFile(path.join(__dirname, '../views/index.html'));
});

router.get('/api/rounds', function(req, res){
  var user = req.query.user;
  Rounds.getRounds(user, function (err, rounds) {
    if (rounds){
      res.json({rounds: rounds});
    } else {
      console.log('index.js - getRounds - err ' + err);
      res.json({err: err + ''});
    }
  });
});

//TODO - send possible courses, players, ... for input-rounds GET

router.post('/api/input-rounds', function(req, res){
  var round = req.body;
  Rounds.inputRounds(round, function (err, success) {
    if (success){
      res.json({success: success});
    } else {
      console.log('index.js - inputRounds - err ' + err);
      res.json({err: err + ''});
    }
  });
});

module.exports = router;
