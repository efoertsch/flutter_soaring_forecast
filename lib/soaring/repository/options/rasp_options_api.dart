import 'package:dio/dio.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:retrofit/retrofit.dart';

part 'rasp_options_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!
@RestApi(baseUrl: Constants.RASP_OPTIONS_BASE_URL)
abstract class RaspOptionsClient {
  factory RaspOptionsClient(Dio dio) = _RaspOptionsClient;

  //!!! soargbsc.com not returning response as json but as string!

  // Get list of turnpoint files
  @GET("/turnpoint_regions.json")
  Future<String> getTurnpointRegions();

  // Get list of SUA files
  @GET("/sua_regions.json")
  //Future<SUARegionFiles> getSUARegions();
  Future<String?> getSUARegions();

  // Get a specific SUA file
  @GET("/{suaFilename}")
  //Future<SUA> downloadSuaFile(@Path("suaFilename") String suaFilename);
  Future<String?> downloadSuaFile(@Path("suaFilename") String suaFilename);

  //Get List of Gliders are related polar info
  @GET("/gliders.json")
  Future<String?> getGliderPolars();
}
