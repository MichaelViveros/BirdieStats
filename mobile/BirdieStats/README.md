###Setup
1. `cordova prepare` - Installs cordova dependencies
2. `npm install` - Install other npm dependencies

<br>
To run in browser: <br>
`cordova build browser`<br>
`cordova run browser` <br>

<br>
To run in android: <br>
`cordova build android` <br>
`cordova run android` <br>
This will run the app on your plugged-in device or emulator.

<br>
Alternatively you can run it in Android Studio: <br>
1. Import Existing Android Code into Android Studio <br>
2. Enter path to platforms/android <br>
3. Select CordovaLib and MainActivity (not the one in build folder) <br>
4. If there's an error with MainActivity project, update it's reference to CordovaLib (right-click project, Properties, Android, Library, Remove CordovaLib if it's there, Add) <br>
5. `cordova build android` <br>
6. Clean the MainActivity project in Android Studio and then Debug it <br>