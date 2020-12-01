<template>
  <div>
    <h2> Rounds</h2>
    <p>{{ msg }}</p>
    <div v-for="(round, i) in rounds" :key="i">
      <h3>Date - {{ round.date }}</h3>
      <h3>Club - {{ round.club }}</h3>

      <div v-for="(course, j) in round.courses" :key="j">
        <h4>Course - {{ course.name }} </h4>
        <h4>Tees - {{ course.tees }} </h4>
        <h4># Holes - {{ course.numHoles }} </h4>

        <table id="table-strokes" border="1" cellpadding="4">
          <tr>
            <th>Hole</th>
            <th v-for="hole in course.holes" :key="hole">{{ hole }}</th>
            <th>Total</th>
            <th>Score</th>
          </tr>
          <tr>
            <td>Yards</td>
            <td v-for="(holeYards, i) in course.yards" :key="i">{{ holeYards }}</td>
            <td>{{ course.totalYards }}</td>
          </tr>
          <tr>
            <td>Par</td>
            <td v-for="(par, i) in course.pars" :key="i">{{ par }}</td>
            <td>{{ course.totalPar }}</td>
          </tr>
          <tr v-for="score in course.scores" :key="score.player">
            <td>{{ score.player }}</td>
            <td v-for="(stroke, i) in score.strokes" :key="i">
              {{ stroke }}
            </td>
            <td><b>{{ score.totalStrokes }}</b></td>
            <td>{{ score.totalScore }}</td>
          </tr>
        </table><br><br>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  name: 'RoundList',
  data: function() {
    return {
      msg: 'Getting rounds ...',
      rounds: []
    }
  },
  created () {
    this.$http.get(
      '/api/rounds',
      {params: {user: ''}}
    ).then(function (response) {
      this.rounds = response.data.rounds;
      this.msg = '';
    }, function (error) {
      console.log(error.data);
      alert(error.data);
    });
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}
</style>
