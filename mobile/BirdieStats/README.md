# BirdieStats App
The BirdieStats app is used to input golf rounds into [birdiestats.com](http://birdiestats.com/). Users can view all their rounds on birdiestats.com.

[Android App](https://play.google.com/store/apps/details?id=com.michaelviveros.BirdieStats&hl=en)

Upcoming features:
* View rounds
* Track statistics like Handicap, Avg. Score on Par 5s, Top 3 Lowest Rounds, ...
* iOS app

This app was built using [Cordova](https://cordova.apache.org/) which lets you develop mobile apps in html and Javascript. This allows you to target multiple platforms like Android and iOS using one code base.

###Setup
Download [NodeJS](https://nodejs.org/en/download/) (if you don't already have it) and run `npm install -g cordova` to get Cordova.

1. `cordova prepare` - Installs cordova dependencies
2. `npm install` - Install other npm dependencies

To run in browser:
* `cordova build browser`
* `cordova run browser`

To run on your Android device or emulator:
* `cordova build android`
* `cordova run android`

Alternatively you can run it in Android Studio:
1. Import Existing Android Code into Android Studio
2. Enter path to platforms/android
3. Select CordovaLib and MainActivity (not the one in build folder)
4. If there's an error with MainActivity project, update it's reference to CordovaLib (right-click project, Properties, Android, Library, Remove CordovaLib if it's there, Add)
5. `cordova build android`
6. Clean the MainActivity project in Android Studio and then Debug it