// main.js
var Vue = require('vue')
var VueResource = require('vue-resource');
var InputRounds = require('./input-rounds.vue')

Vue.use(VueResource);

var vm = new Vue({
  el: 'body',
  components: {
    'input-rounds': InputRounds
  }
});

vm.$broadcast('init-input-rounds');