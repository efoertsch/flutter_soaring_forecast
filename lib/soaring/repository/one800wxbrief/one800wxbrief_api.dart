import 'package:dio/dio.dart' hide Headers;
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/metar.dart';
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/route_briefing.dart';
import 'package:flutter_soaring_forecast/soaring/repository/one800wxbrief/taf.dart';
import 'package:retrofit/retrofit.dart';

part 'one800wxbrief_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!
@RestApi(baseUrl: Constants.WXBRIEF_URL)
abstract class One800WxBriefClient {
  factory One800WxBriefClient(Dio dio) = _One800WxBriefClient;

  // Get a METAR (mainly for testing 1800wxbrief api. App get METARS from other source
  @GET("/retrieveMETAR")
  @Headers(<String, dynamic>{
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": "Soaring Forecast FFSP Interface"
  })
  Future<Metar> getMETAR(@Header("Authorization") String basicBase64,
      @Query("location") String airport);

  // Get a METAR (mainly for testing 1800wxbrief api. App get METARS from other source
  @GET("/retrieveTAF")
  @Headers(<String, dynamic>{
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": "Soaring Forecast FFSP Interface"
  })
  Future<Taf> getTAF(@Header("Authorization") String basicBase64,
      @Query("location") String airport);

  @POST("FP/routeBriefing")
  @Headers(<String, dynamic>{
    "Content-Type": "application/x-www-form-urlencoded",
    "User-Agent": "Soaring Forecast FFSP Interface"
  })
  Future<RouteBriefing> getRouteBriefing(
      @Header("Authorization") String basicBase64,
      @Body() String completeQueryString);
}
