Chateau = require "./chateau"

if PACKAGE.name is "ROOT"
  {Style} = require "ui"
  style = document.createElement "style"
  style.innerHTML = Style.all + "\n" + require("./style")
  document.head.appendChild style

  # Initialize Firebase
  firebase.initializeApp
    apiKey: "AIzaSyCnhTPOri3XGQ0q5pw0u8dRPZQwr74fpuw"
    authDomain: "chateau-f2799.firebaseapp.com"
    databaseURL: "https://chateau-f2799.firebaseio.com"
    storageBucket: "chateau-f2799.appspot.com"
    messagingSenderId: "2073045470"

  global.logger = require("./lib/logger")(console.log)
  global.stats = require("./lib/stats")()
  global.firebase = firebase
  global.db = firebase.database()
  global.defaults = require("./util").defaults
  global.chateau = Chateau(firebase)

  document.body.appendChild chateau.element
else
  module.exports = Chateau
