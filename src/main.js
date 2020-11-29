import Vue from 'vue'
import App from './App.vue'
import VueResource from 'vue-resource'
import VTooltip from 'v-tooltip'
import VueNumeric from 'vue-numeric'

Vue.use(VueResource);
Vue.use(VTooltip)
Vue.use(VueNumeric)

Vue.config.productionTip = false

new Vue({
  render: h => h(App),
}).$mount('#app')
