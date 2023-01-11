
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
2. For an APK build to build and install from AS terminal (for testing before creating bundle)
   flutter build apk --flavor prod --split-per-abi    
3. Install apk (check - make sure apk path and name correct based on build output )
   adb install build/app/outputs/flutter-apk/app-armeabi-v7a-prod-release.apk

4. WIP - debug building obfuscated apl
      flutter build apk --flavor prod --split-per-abi --obfuscate --split-debug-info=/flutter_soaring_forecast/android/release_debug_symbols
5. WIP Rename symbols file so it won't be overwritten next time release apk built
6. After testing apk rebuild using package option
7. Upload to Google PlayStore

