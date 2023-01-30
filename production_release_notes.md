
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
2. To create an APK, install from AS terminal (for testing before creating bundle)
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
7. After testing upload or move test version on play store to production


