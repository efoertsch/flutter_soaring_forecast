import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import 'forecast_models.dart';
import 'regions.dart';

part 'rasp_api.g.dart';

//TODO put baseUrl in separate file so can be changed to another URL easily
@RestApi(baseUrl: "https://soargbsc.com/rasp/")
abstract class RaspClient {
  factory RaspClient(Dio dio) = _RaspClient;

  @GET("current.json")
  Future<Regions> getRegions();

  @GET("{region}/{date}/status.json")
  Future<ForecastModels> getForecastModels(
      @Path("region") String region, @Path("date") String date);
}
