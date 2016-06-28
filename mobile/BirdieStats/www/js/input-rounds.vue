// input-rounds.vue
<style>
td {
  text-align: center;
  vertical-align: middle;
}
</style>

<template>
	<h3>Input Rounds</h3>

  <p>{{statusMsg}}</p>

  <!-- Date -->
  <input v-model="date" type="date"><br><br>
  <!-- Club -->
  <select v-model="club" @change="changeClub">
    <option value="" default selected disabled>Select club</option>
    <option v-for="clubOpt in clubOptions">
      {{ clubOpt.name }}
    </option>
  </select><br><br>
  <!-- Players -->
  <table id="table-players" cellpadding="6">
    <tr v-for="i in players.length">
      <td>
        <select v-model="players[i]">
          <option value="" default selected disabled>Select player</option>
          <option v-for="player in playerOptions">
            {{ player }}
          </option>
        </select>
      </td>
    <tr>   
  </table><br>
  <button id="btn-add-player" @click="addPlayer" v-bind:disabled="!canAddPlayers">Add Player</button>
  <button id="btn-remove-player" @click="removePlayer" v-bind:disabled="players.length == 1">Remove Player</button><br><br>

  <div id="div-courses" v-for="i in courses.length">
    <!-- Course -->
    <select v-model="courses[i].name" @change="changeCourse(i)">
      <option value="" default selected disabled>Select course</option>
      <option v-for="course in courseOptions">
        {{ course.name }}
      </option>
    </select><br><br>
    <!-- Tees -->
    <select v-model="courses[i].tees">
      <option value="" default selected disabled>Select tees</option>
      <option v-for="tees in teeOptions">
        {{ tees }}
      </option>
    </select><br><br>
    <!-- NumHoles -->
    <input v-model="courses[i].numHoles" number type="number" min="1" max="18" placeholder="# holes"><br><br>
    <!-- Strokes -->
    <table cellpadding="4">
      <tr>
        <th>Hole</th>
        <th v-for="j in players.length">{{players[j]}}</th>
      </tr>
      <tr v-for="j in courses[i].numHoles">
        <td>{{j+1}}</td>
        <td v-for="k in players.length">
          <input v-model="courses[i].strokes[k][j]" number type="number" min="0" max="20" align="center">
        </td>
      </tr>
    </table><br>
  </div>
  <button id="btn-add-course" @click="addCourse" v-bind:disabled="!canAddCourses">Add Course</button>
  <button id="btn-remove-course" @click="removeCourse" v-bind:disabled="courses.length == 1">Remove Course</button><br><br>

  <button id="btn-done-input-rounds" @click="sendInputRounds">Done</button>
  <button id="btn-cancel-input-rounds" @click="cancelInputRounds">Cancel</button>

</template>

<script>
var config = require('../../config'); 
export default {
  data () {
    return {
      date: '',
      club: '',
      courses: [],
      canAddPlayers: false,
      canAddCourses: false,
      players: [],
      statusMsg: '',
      playerOptions: [],
      clubOptions: [],
      courseOptions: [],
      teeOptions: []
    }
  },
  methods: {
    sendInputRounds: function() {
      var errors = this.prepareInputRounds();
      if (errors) {
        alert(errors);
        return;
      }

      this.$http.post(
        config.server + 'api/input-rounds',
        {
          date: this.date,
          club: this.club,
          courses: this.courses,
          players: this.players
        }
      ).then(function (response) {
        var success = response.data.success;
        if (response.data.success) {
          this.reset('Input Round successful');
        } else {
          alert(response.data.err);
          this.refillStrokes();
        }
      }, function (error) {
        console.log(error.data);
        alert(error.data);
        this.refillStrokes();
      });
    },
    prepareInputRounds: function() {
      if (!this.date) return "Missing Date";
      if (!this.club) return "Missing Club";
      for (var i = 0; i < this.players.length; i++) {
        if (!this.players[i]) return "Missing Name for Player " + (i + 1);
      }
      for (var i = 0; i < this.courses.length; i++) {
        if (!this.courses[i].name) return "Missing Course " + (i + 1);
        if (!this.courses[i].tees) return "Missing Tees for Course " + (i + 1);
        if (!this.courses[i].numHoles) return "Missing Number of Holes for Course " + (i + 1);
      }

      for (var i = 0; i < this.courses.length; i++) {
        for (var j = 0; j < this.players.length; j++) {
          var first0 = this.courses[i].strokes[j].indexOf(0);
          if (first0 != -1 && first0 < this.courses[i].numHoles) {
            return 'Missing Strokes.\nCourse - ' + (i + 1) + '\nPlayer - ' + 
              this.players[j] + '\nHole - ' + (first0 + 1);
          }
        }
      }

      // create holeFlags such that if holeFlags[j] = 1, there are strokes for hole j
      for (var i = 0; i < this.courses.length; i++) {
        this.courses[i].holeFlags = new Array(18).fill(0);
        for (var j = 0; j < this.courses[i].numHoles; j++) {
          var p1Strokes = this.courses[i].strokes[0];
          if (p1Strokes[j] != 0) {
            this.courses[i].holeFlags[j] = 1;
          }
        }
      }
    },
    refillStrokes: function() {
      for (var i = 0; i < this.courses.length; i++) {
        for (var j = 0; j < this.players.length; j++) {
          var extraZeroes = new Array(18 - this.courses[i].numHoles).fill(0);
          this.courses[i].strokes[j] = this.courses[i].strokes[j].concat(extraZeroes);
        }
      }
    },
    cancelInputRounds: function() {
      this.reset('');
    },
    addPlayer: function() {
      this.players.push('');
      for (var i = 0; i < this.courses.length; i++) {
        this.courses[i].strokes.push(new Array(18).fill(0));
      }
      if (this.players.length == 4) {
        this.canAddPlayers = false;
      }
    },
    removePlayer: function() {
      this.players.pop();
      for (var i = 0; i < this.courses.length; i++) {
        this.courses[i].strokes.pop();
      }
      if (!this.canAddPlayers) {
        this.canAddPlayers = true;
      }
    },
    addCourse: function() {
      var courseStrokes = [];
      for (var i = 0; i < this.players.length; i++) {
        courseStrokes.push(new Array(18).fill(0));
      }
      this.courses.push({
        name: '',
        tees: '',
        numHoles: this.courses[0].numHoles,
        strokes: courseStrokes
      });
      if (this.courses.length == 2) {
        this.canAddCourses = false;
      }
    },
    removeCourse: function() {
      this.courses.pop();
      if (!this.canAddCourses) {
        this.canAddCourses = true;
      }
    },
    changeClub: function() {
      this.courseOptions = this.clubOptions.find(c => c.name == this.club).courses;
      this.teeOptions = [];
    },
    changeCourse: function(courseIndex) {
      this.teeOptions = this.courseOptions.find(c => c.name == this.courses[courseIndex].name).tees;
    },
    reset: function(statusMsg) {
      this.statusMsg = statusMsg;
      this.date = '';
      this.club = '';
      this.courses = [];
      this.courses.push({
        name: '',
        tees: '',
        numHoles: null,
        strokes: [new Array(18).fill(0)]
      });
      this.canAddPlayers = true;
      this.canAddCourses = true;
      this.players = [''];
    }
  },
  events: {
    'init-input-rounds': function () {
      this.reset('Setting up input rounds ...');
      this.clubOptions = [];
      this.playerOptions = [];
      this.courseOptions = [];
      this.teeOptions = [];

      this.$http.get(
        config.server + 'api/input-rounds'
      ).then(function (response) {
        this.clubOptions = response.data.clubs;
        this.playerOptions = response.data.players;
      }, function (error) {
        alert(error.data);
      });
      this.statusMsg = '';
    }
  }
}
</script>