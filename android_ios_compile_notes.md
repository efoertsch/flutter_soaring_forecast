TODO: implement flutter_flavorizr - https://pub.dev/packages/flutter_flavorizr

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
7. After testing upload or move test version on play store to production


