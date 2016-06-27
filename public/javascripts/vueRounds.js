var vm = new Vue({
    el: "#vue-golf-rounds",
    data: {
        layoutType: '',
        rounds: [],
        userName: '',
        showGetRounds: false,
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
    },
    methods: {
        getRounds: function() {
            this.statusMsg = 'Getting rounds ...';
            this.$http.get(
                '/api/rounds',
                {user: this.userName}
            ).then(function (response) {
                this.rounds = response.data.rounds;
                if (this.rounds.length == 0) {
                    this.statusMsg = 'No rounds found for user ' + this.userName;
                } else {
                    this.statusMsg = '';
                }
            }, function (error) {
                console.log(error.data);
                alert(error.data);
            });
        },
        inputRounds: function() {
            this.statusMsg = 'Setting up input rounds ...';
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
            this.clubOptions = [];
            this.playerOptions = [];
            this.courseOptions = [];
            this.teeOptions = [];

            this.$http.get(
                '/api/input-rounds'
            ).then(function (response) {
                this.clubOptions = response.data.clubs;
                this.playerOptions = response.data.players;
                this.showGetRounds = false;
            }, function (error) {
                console.log(error.data);
                alert(error.data);
            });
        },
        sendInputRounds: function() {
            var errors = this.prepareInputRounds();
            if (errors) {
                alert(errors);
                return;
            }

            this.$http.post(
                '/api/input-rounds',
                {
                    date: this.date,
                    club: this.club,
                    courses: this.courses,
                    players: this.players
                }
            ).then(function (response) {
                var success = response.data.success;
                if (response.data.success) {
                    this.showHomeView('Input Round successful');
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
            if (!this.date) return "Missing date";
            if (!this.club) return "Missing club";
            for (var i = 0; i < this.players.length; i++) {
                if (!this.players[i]) return "Missing name for player " + (i + 1);
            }
            for (var i = 0; i < this.courses.length; i++) {
                if (!this.courses[i].name) return "Missing name for course " + (i + 1);
                if (!this.courses[i].tees) return "Missing tees for course " + (i + 1);
                if (!this.courses[i].numHoles) return "Missing number of holes for course " + (i + 1);
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
            this.showHomeView('');
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
        showHomeView: function(statusMsg) {
            this.statusMsg = statusMsg;
            this.userName = '';
            this.rounds = [];
            this.layoutType = 'horizontal';
            this.showGetRounds = true;
        }
    }
});

vm.showHomeView('');