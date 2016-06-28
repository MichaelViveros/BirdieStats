var fs = require("fs")
var browserify = require('browserify')
var vueify = require('vueify')

browserify('www/js/main.js')
  .transform(vueify)
  .bundle()
  .pipe(fs.createWriteStream("www/js/bundle.js"))