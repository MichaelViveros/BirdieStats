<template>
  <div>
    <h2>Input Rounds</h2>
    <p>{{ msg }}</p>
    
    <input v-model="date" type="text" size="35" placeholder="Enter date, yyyy-mm-dd"><br><br>
    
    <select v-model="club" @change="changeClub">
      <option :value="{}" default selected disabled>Select club</option>
      <option v-for="clubOpt in clubOptions" :key="clubOpt.name"
      :value="clubOpt">
        {{ clubOpt.name }}
      </option>
    </select><br><br>

    <table>
      <tr v-for="(course, i) in courses" :key="course.name">
        <td>{{ course.name }}</td>
        <td>
          <button @click="removeCourse(i)">Remove</button>
        </td>
      </tr>
      <tr v-if="canAddCourses">
        <td>
          <select v-model="newCourse">
            <option :value="{}" default selected disabled>Select course</option>
            <option v-for="course in newCourseOptions" :key="course.name"
            :value="course">
              {{ course.name }}
            </option>
          </select>
        </td>
        <td>
          <button @click="addCourse"
          :disabled="Object.keys(newCourse).length == 0">
            Add
          </button>
        </td>
      </tr>
    </table><br>

    <div v-for="(course, courseIndex) in courses" :key="course.name">
      <h4>Course - {{ course.name }} </h4>
      
      <select v-model="course.tees">
        <option value="" default selected disabled>Select tees</option>
        <option v-for="tees in course.teesOptions" :key="tees">
          {{ tees }}
        </option>
      </select><br><br>

      <vue-numeric v-model="course.numHoles" min="1" max="18" 
      placeholder="# holes" @change="changeNumHoles(courseIndex)">
      </vue-numeric><br><br>
      
      <table border="1" cellpadding="4">
        <tr>
          <th>Hole</th>
          <th v-for="num in course.numHoles" :key="num">{{ num }}</th>
        </tr>
        <tr v-for="(score, scoreIndex) in course.scores"  :key="score.player">
          <td>
            {{ score.player }}
            <button @click="removeScore(scoreIndex, courseIndex)">
              Remove
            </button>
          </td>
          <td v-for="num in course.numHoles" :key="num">
            <vue-numeric v-model="score.strokes[num - 1]" 
            style="width: 35px;" min="0" max="20"></vue-numeric>
          </td>
        </tr>
        <tr v-show="canAddScores">
          <td>
            <select v-model="newPlayer">
              <option value="" default selected disabled>Select player</option>
              <option v-for="player in newPlayerOptions" :key="player">
                {{ player }}
              </option>
            </select>
            <button @click="addScore" :disabled="newPlayer == ''">Add</button>
          </td>
        </tr>
      </table><br><br>
    </div>

    <!-- wrap the button in a div so that tooltip can be showed
    when button is disabled -->
    <div v-tooltip="submitWarningMsg">
      <button v-on:click="submit"
      :disabled="submitWarningMsg != ''">
        Submit
      </button>
    </div>

  </div>
</template>

<script>
export default {
  name: 'RoundForm',
  data: function() {
    return {
      msg: 'Getting input data ...',
      date: '',
      club: {},
      courses: [],
      newCourse: {},
      newPlayer: '',
      clubOptions: [],
      courseOptions: [],
      playerOptions: [],
    }
  },
  computed: {
    newCourseOptions () {
      let existingCourses = this.courses.map(c => c.name)
      return this.courseOptions.filter(c => !existingCourses.includes(c.name))
    },
    canAddCourses () {
      return this.courses.length < 2
    },
    newPlayerOptions () {
      if (this.courses.length == 0) {
        return []
      }
      let players = this.courses[0].scores.map(s => s.player)
      return this.playerOptions.filter(p => !players.includes(p))
    },
    canAddScores () {
      return this.courses[0].scores.length < 4
    },
    submitWarningMsg () {
      if (!this.date) return 'Missing date'
      if (Object.keys(this.club).length == 0) return 'Missing club'
      if (this.courses.length == 0)  return 'Missing course'
      if (!this.courses.every(c => c.tees)) return 'Missing tees'
      if (!this.courses.every(c => c.numHoles > 0)) return 'Missing holes'
      if (!this.courses.every(c => c.scores.length > 0)) {
        return 'Missing players'
      }
      let strokes = this.courses.flatMap(c => c.scores.flatMap(s => s.strokes))
      if (strokes.includes(0)) {
       return 'Missing scores. All scores must be greater than 0'
      }
      return ''
    },
  },
  created () {
    this.$http.get(
      '/api/input-rounds'
    ).then(function (response) {
      this.clubOptions = response.data.clubs;
      this.playerOptions = response.data.players;
      this.msg = 'Input new round below.'
    }, function (error) {
      console.log(error.data);
      alert(error.data);
    })
  },
  methods: {
    changeClub: function() {
      this.courses = []
      this.courseOptions = this.club.courses
    },
    addCourse: function() {
      this.courses.push({
        name: this.newCourse.name,
        teesOptions: this.newCourse.tees,
        tees: '',
        numHoles: 0,
        scores: [],
      })
      this.newCourse = {}
    },
    removeCourse: function(index) {
      this.courses.splice(index, 1)
    },
    changeNumHoles(courseIndex) {
      let course = this.courses[courseIndex]
      if (course.scores.length == 0) {
        return
      }
      let oldStrokesLength = course.scores[0].strokes.length
      let diff = course.numHoles - oldStrokesLength
      if (diff > 0) {
        let strokes = Array(diff).fill(0)
        course.scores.forEach(s => s.strokes.push(...strokes))
      } else {
        // start splicing after the "numHoles" index, so numHoles + 1,
        // but numHoles is 1-indexed, so start at numHoles
        // Ex. numHoles = 3, start splicing at index 3
        let startIndex = course.numHoles
        course.scores.forEach(s => s.strokes.splice(startIndex))
      }
    },
    addScore: function() {
      for (let course of this.courses) {
        course.scores.push({
          player: this.newPlayer,
          strokes: Array(course.numHoles).fill(0),
        })
      }
      this.newPlayer = ''
    },
    removeScore: function(scoreIndex, courseIndex) {
      this.courses[courseIndex].scores.splice(scoreIndex, 1)
    },
    submit: function() {
      let courses = this.courses.map(function(course) {
        let holeFlags = Array(course.numHoles).fill(1)
        holeFlags.push(...Array(18 - course.numHoles).fill(0))
        let strokes = course.scores.map(function(score) {
          return score.strokes.concat(Array(18 - course.numHoles).fill(0))
        })
        return {
          name: course.name,
          tees: course.tees,
          numHoles: course.numHoles,
          holeFlags,
          strokes,
        }
      })
      let players = this.courses[0].scores.map(s => s.player)
      this.$http.post(
        '/api/input-rounds',
        {
          date: this.date,
          club: this.club.name,
          courses,
          players
        }
      )
      .then(function (response) {
        if (response.data.success) {
          this.$emit('finish-inputting-round');
        } else {
          alert(response.data.err);
        }
      }, function (error) {
        alert(error.data);
      })
    }
  }
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
