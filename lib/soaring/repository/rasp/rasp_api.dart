import 'package:dio/dio.dart';
import 'package:flutter_soaring_forecast/soaring/app/constants.dart'
    as Constants;
import 'package:retrofit/retrofit.dart';

import 'forecast_models.dart';
import 'regions.dart';

part 'rasp_api.g.dart';

//!!! Remember to run generator with any changes !!!
//!!!  flutter pub run build_runner build  --delete-conflicting-outputs     !!!
@RestApi(baseUrl: Constants.RASP_BASE_URL)
abstract class RaspClient {
  factory RaspClient(Dio dio) = _RaspClient;

  @GET("/current.json")
  Future<Regions> getRegions();

  @GET("/{region}/{date}/status.json")
  Future<ForecastModels> getForecastModels(
      @Path("region") String region, @Path("date") String date);

  /*
  * @param region - NewEngland
  * @param yyyymmddDate - 2018-03-31
  * @param forecastType - gfs
  * @param forecastParameter - wstar_bsratio
  * @param forecastTime - 1500
  * @param bitmapType - body
  * @return something like NewEngland/2018-03-31/gfs/wstar_bsratio.1500local.d2.body.png
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
      @Field("param") String forecastType);
}
