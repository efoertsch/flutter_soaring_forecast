import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart' hide Headers;

import 'national_map.dart';

part 'usgs_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!
@RestApi()
abstract class UsgsClient {
  factory UsgsClient(Dio dio) = _UsgsClient;

  @GET("https://epqs.nationalmap.gov/v1/json?wkid=4326&includeDate=false")
  @Headers(<String, dynamic>{"accept": "application/json"})
  Future<NationalMap> getElevation(@Query("y") String latitude,
      @Query("x") String longitude, @Query("units") String units);
}
