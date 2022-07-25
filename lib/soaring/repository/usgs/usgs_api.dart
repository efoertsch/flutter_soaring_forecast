import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'national_map.dart';

part 'usgs_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!
@RestApi()
abstract class UsgsClient {
  factory UsgsClient(Dio dio) = _UsgsClient;

  @GET("https://nationalmap.gov/epqs/pqs.php?output=json")
  Future<NationalMap> getElevation(@Query("y") String latitude,
      @Query("x") String longitude, @Query("units") String units);
}
