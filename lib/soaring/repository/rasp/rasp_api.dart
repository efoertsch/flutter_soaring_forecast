import 'package:dio/dio.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:retrofit/retrofit.dart';

import 'forecast_models.dart';
import 'regions.dart';

part 'rasp_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  dart run build_runner build  --delete-conflicting-outputs     !!!
@RestApi(baseUrl: Constants.RASP_BASE_URL)
abstract class RaspClient {
  factory RaspClient(Dio dio) = _RaspClient;

  @GET("/current.json")
  Future<Regions> getRegions();

  @GET("/{region}/{date}/status.json")
  Future<ForecastModels> getForecastModels(
      @Path("region") String region, @Path("date") String date);

  /*
  * @param region - "NewEngland"
  * @param date - "2018-03-31"
  * @param model - "gfs"
  * @param time - "1500"
  * @param lat - "43.1394043"
  * @param lon - "-72.0759888"
  * @param param  -  "wstar hwcrit" space separated forecast codes
  * @return
  */
  // Got error when putting Content-type in @Headers annotation
  @POST("/cgi/get_rasp_blipspot.cgi")
  Future<HttpResponse> getLatLongPointForecast(
      @Header("Content-Type") String contentType,
      @Field("region") String region,
      @Field("date") String date,
      @Field("model") String model,
      @Field("time") String time,
      @Field("lat") String lat,
      @Field("lon") String lon,
      @Field("param") String forecasts);

/*
  * @param region - "NewEngland"
  * @param date - "2018-03-31"
  * @param model - "gfs"
  * @param time - "0900@1000@1100"   times separated by @
  * @param lat - "43.1394043"
  * @param lon - "-72.0759888"
  * @param param  -  "wstar@hwcrit" @ separated forecast codes
  * @return
  */
// Got error when putting Content-type in @Headers annotation
  @GET("/cgi/get_multirasp_blipspot.cgi")
  Future<HttpResponse<String>> getDaysForecastForLatLong(
      @Header("Content-Type") String contentType,
      @Query("region") String region,
      @Query("date") String date,
      @Query("model") String model,
      @Query("time") String time,
      @Query("lat") String lat,
      @Query("lon") String lon,
      @Query("param") String forecasts);

  @GET("/cgi/get_estimated_flight_avg.cgi")
  Future<HttpResponse<String>> getEstimatedFlightAverages(
      @Header("Content-Type") String contentType,
      @Query("region") String region,
      @Query("date") String date,
      @Query("model") String model,
      @Query("grid") String grid,
      @Query("time") String time,
      @Query("glider") String glider,
      @Query("polarFactor") double polarFactor,
      @Query("polarCoefficients") String polarCoefficients , // a, b, c
      @Query("tsink") double thermalSinkRate,
      @Query("tmult") double thermalMultipler,
      @Query("turnpts") String latlons);

}
