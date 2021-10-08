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

//  /*
//   * @param region - NewEngland
//   * @param yyyymmddDate - 2018-03-31
//   * @param forecastType - gfs
//   * @param forecastParameter - wstar_bsratio
//   * @param forecastTime - 1500
//   * @param bitmapType - body
//   * @return something like NewEngland/2018-03-31/gfs/wstar_bsratio.1500local.d2.body.png
//   */
//  @GET(
//      "/{region}/{date}/{forecastType}/{forecastParameter}.{forecastTime}local.d2.{bitmapType}.png")
//  Future<Stream> getForecastOverlays(
//      @Path("region") String region,
//      @Path("date") String date,
//      @Path("forecastType") String forecastType,
//      @Path("forecastParameter") String forecastParameter,
//      @Path("forecastTime") String forecastTime,
//      @Path("bitmapType") String bitmapType);
}
