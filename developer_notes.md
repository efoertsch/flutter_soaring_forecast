Glider Polar info used in task Estimated Flight logic
1. Polar info was obtained from Github XCSOAR -> XCSoar/src/Polar/PolarStore.cpp
2. The cpp file was editted to remove comments and extraneous stuff to get CSV format that could then be 
imported into a Google Sheet - https://docs.google.com/spreadsheets/d/11s6b0BEiOLh2ITzhs9nVlh9HWSmoBeUtlxkrAEwkKUs/edit?usp=sharing
3. The sheet was formatted, column headers added, etc. 
4. The 'Polar JSON' tab and formulas were created to format the 'PolarData' tab data to a form that was
then copied/pasted into the assets/json/gliders.json  file.

!!! MacOS updates may overwrite the httpd.conf file. If don't get proper response from local server check
!!! to make sure httpd.conf is correct.
Stuff I forget for configuring local RASP server on my Mac.
This doesn't cover setting up getting a copy of the prod RASP html/forecast files  (ask Steve Paavola)
and nor setting up the Apache server to run RASP website
There are probably easier ways to do this but...
1. Apache config file at /private/etc/apache2/httpd.conf
2. Open term
3. cd /private/etc/apache2
4. sudo nano httpd.conf
5. Scroll down and comment out current DocumentRoot
6. Uncomment #DocumentRoot "/Users/ericfoertsch/Sites/rasp/HTML"
7. Stop/start server
   sudo apachectl stop
   sudo apachectl start
8. Open browser and go to http://127.0.0.1/  to ensure server running
9. To compile app to use local server comment/uncomment lines in Constants file
   Set ip address/port to current laptop address (.11 is likely to change)
   const String RASP_BASE_URL ='http://192.168.1.7/'   <<< Final number may change so check
10. Regen the api's
    dart run build_runner build  --delete-conflicting-outputs

Installing perl visual debugger. 
1. Found StackOverflow reference to install debugger via 
   sudo cpan Tk
   sudo cpan Devel::ptkdb
2. Looked like Tk install, but ptkdb install kept falling as it couldn't find Tk.pm
3. Found link to install Tk.pm
   sudo perl -MCPAN -e shell
   at prompt did install Tk
4. Reran sudo cpan Devel::ptkdb

Debugging server side perl scripts
The perl visual debugger was used to help trace and debug changes in  get_estimated_flight_avg.PL - a
server side perl script used to get estimated task info (leg/task time, estimated climb rates, etc)
From the local RASP sever cgi directory, the perl script was executed via:
   perl -d:ptkdb get_estimated_flight_avg.PL ../NewEngland/2023-08-11/gfs NewEngland  d2 1000x  "LS-4" 1 "-0.00020,0.03500,-2.19000" 0.9092095622654608 1.0 turnpts ",42.42616666666667,-71.79383333333332,Ster,2,43.3705,-72.368,Clar,3,42.100833333333334,-72.03883333333333,Sout,4,42.42616666666667,-71.79383333333332,Ster"

For executing skip to get Local Forecast via get_multirasp_blipspot:
  curl "http://192.168.1.7/cgi/get_multirasp_blipspot.cgi?region=NewEngland&date=2023-08-11&model=gfs&time=1000%401100%401200%401300%401400%401500%401600%401700%401800&lat=42.805&lon=-72.00283333333333&param=experimental1%40zsfclcldif%40zsfclcl%40zblcldif%40zblcl%40wstar%40sfcwind0spd%40sfcwind0dir%40sfcwindspd%40sfcwinddir%40blwindspd%40blwinddir%40bltopwindspd%40bltopwinddir"

Direct call to extract.blipspot.PL (For testing on local server)
perl extract.blipspot.PL /Users/ericfoertsch/Sites/rasp/HTML/NewEngland/2023-08-11/gfs NewEngland 42.805 -72.00283333333333 0 1000 1100 1200 1300 1400 1500 1600 1700 1800 experimental1 zsfclcldif zsfclcl zblcldif zblcl wstar sfcwind0spd sfcwind0dir sfcwindspd sfcwinddir blwindspd blwinddir bltopwindspd bltopwinddir

Apache2 error log on Mac can be listed via:
    cat /var/log/apache2/error_log


TODO: implement flutter_flavorizr - https://pub.dev/packages/flutter_flavorizr

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
Prior to production compile, ensure proper RASP_BASE_URL value is set
for Production and the API's are regen'ed. 
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Development:

For Android:

Two flavors have been created - dev and prod.
Options to execute/build the different flavors
1. Go to Run/Edit Configurations
    1. Under Flutter/main.dart and 'Additional run args' add '--flavor dev' (or prod)
    2. With this option you can click on run/debug icons

2. From the terminal window
    1. Start an emulator if needed
    2. Execute from terminal (can't click on run/debug icons)
       flutter run --flavor dev (or prod)
    3. Note this ties up terminal and you need to cntrl-c to stop

For iOS:
1. Currently just the one flavor. If need be  Remove the Android flavor from Run/Edit
    1. Under Flutter/main.dart and 'Additional run args' remove '--flavor dev'


Production:

For any production release:
1. Update release number in pubspec.yml

iOS release

Apple signing certificates may expire and need to be renewed. Because I don't have an iPhone I need
to manually manage generating and assigning new certificates. I found instructions via google query
"update expired provisioning profile for iOS app"

After repeated warnings ' warning: The iOS deployment target 'IPHONEOS_DEPLOYMENT_TARGET' is set to 8.0, but
the range of supported deployment target versions is 11.0 to 16.1.99.'
1. Based on https://stackoverflow.com/questions/63973136/the-ios-deployment-target-iphoneos-deployment-target-is-set-to-8-0-in-flutter)
    1. Added line in ios/Podfile
       config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'

2. If generating un-obfuscated code:
    1. flutter build ipa
    2. Invariably gives error:
        1. Encountered error while creating the IPA:
           error: exportArchive: "Runner.app" requires a provisioning profile.
           Try distributing the app in Xcode: "open /Users/ericfoertsch/Documents/git/flutter_soaring_forecast/build/ios/archive/Runner.xcarchive"
    3. So execute given command:
        1. open /Users/ericfoertsch/Documents/git/flutter_soaring_forecast/build/ios/archive/Runner.xcarchive


2. To generate obfuscated code:
    1. Execute build command:
       flutter build ipa --obfuscate --split-debug-info=build/app/outputs/symbols
    2. Fails with similar error above
    3. Execute:
       open /Users/ericfoertsch/Documents/git/flutter_soaring_forecast/build/ios/archive/Runner.xcarchive


Android release
Reference obfuscate process at https://docs.flutter.dev/deployment/obfuscate
1. Make sure build.gradle has correct package name
2. To create an APK, install from AS terminal (for testing before creating bundle).
   Note that you will need to uninstall any Play Store version as signing doesn't match
   (Apk gets your laptop signature, Play app bundle gets Googles)
   flutter build apk --flavor prod --split-per-abi --obfuscate --split-debug-info=./android/release_debug_symbols
3. Install apk (check - make sure apk path and name correct based on build output ) based on device architecture.
   Example below is for arm device.
   adb install build/app/outputs/flutter-apk/app-armeabi-v7a-prod-release.apk (match release type to device)
4. To create app bundle:
   flutter build appbundle  --flavor prod --obfuscate --split-debug-info=./android/release_debug_symbols

   In this case output went to: build/app/outputs/bundle/prodRelease/app-prod-release.aab
5. Upload to Play Store test track or test app bundle using bundletool (https://github.com/google/bundletool).
6. Upload symbols file to play store:
   Files to upload: https://stackoverflow.com/questions/62568757/playstore-error-app-bundle-contains-native-code-and-youve-not-uploaded-debug/68778908#68778908
   How to upload: https://docs.unity3d.com/ru/2021.1/Manual/android-symbols.html#:~:text=To%20do%20this%2C%20click%20the,zip).&text=After%20you%20upload%20the%20symbols,information%20on%20what%20went%20wrong.
   If get upload error about the zip file having Mac symbols
      https://stackoverflow.com/questions/76621039/flutter-the-native-debug-symbols-contain-an-invalid-directory-macosx-when-up

   zip -d Archive.zip "__MACOSX*" 



