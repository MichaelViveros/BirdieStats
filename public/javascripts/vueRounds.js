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
                strokes: []
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
                }
            }, function (error) {
                console.log(error.data);
                alert(error.data);
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

            // populate strokes for each course, since it did not use data binding
            var playerStrokes = [];
            var courseStrokes = [];
            var playerCount = 0;
            var courseIndex = 0;
            var missingStrokes = false;
            // have to make vm variable since "this" inside jquery code refers to html element, not the Vue object
            var vm = this;
            $('#div-courses > table').find('input').each(function () {
                var strokes = $(this).val();
                if (strokes.length == 0) {
                    missingStrokes = true;
                    return false;
                }
                playerStrokes.push(strokes);
                if (playerStrokes.length == vm.courses[courseIndex].numHoles) {
                    courseStrokes.push(playerStrokes);
                    playerStrokes = [];
                    playerCount++;
                }
                if (playerCount == vm.players.length) {
                    vm.courses[courseIndex].strokes = courseStrokes;
                    courseStrokes = [];
                    courseIndex++;
                    playerCount = 0;
                }
            });
            if (missingStrokes) {
                return 'Missing strokes.\ncourse - ' + vm.courses[courseIndex].name + '\nplayer - ' + 
                    vm.players[playerCount] + '\nhole - ' + (playerStrokes.length + 1);
            }

            // populate holes for each course, since it did not use data binding
            for (var i = 0; i < this.courses.length; i++) {
                this.courses[i].holes = [];
                for (var j = 0; j < this.courses[i].numHoles; j++) {
                   this.courses[i].holes.push(j + 1);
                }
            }

        },
        cancelInputRounds: function() {
            this.showHomeView('');
        },
        addPlayer: function() {
            this.players.push('');
            if (this.players.length == 4) {
                this.canAddPlayers = false;
            }
        },
        removePlayer: function() {
            this.players.pop();
            if (!this.canAddPlayers) {
                this.canAddPlayers = true;
            }
        },
        addCourse: function() {
            this.courses.push({
                name: '',
                tees: '',
                numHoles: this.courses[0].numHoles,
                strokes: []
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