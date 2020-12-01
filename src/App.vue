<template>
  <div id="app">
    <header>
      <h1>Birdie Stats</h1>
    </header>
    <button id="btn-input-round" @click="isInputting = true" 
    v-bind:disabled="isInputting">
      Input New Round
    </button><br><br>
    <RoundForm v-if="isInputting"
    v-on:finish-inputting-round="isInputting = false"/>
    <RoundList v-else/>
  </div>
</template>

<script>
import RoundForm from './components/RoundForm.vue'
import RoundList from './components/RoundList.vue'

export default {
  name: 'App',
  components: {
    RoundForm,
    RoundList,
  },
  data: function() {
    return {
      isInputting: false,
    }
  },
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

#app table {
  margin-left: auto;
  margin-right: auto;
}

</style>
