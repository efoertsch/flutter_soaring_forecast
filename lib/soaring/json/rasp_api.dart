
import 'package:retrofit/retrofit.dart';
import 'package:dio/dio.dart';
import 'regions.dart';
import 'forecast_models.dart';

part 'rasp_api.g.dart';

@RestApi(baseUrl: "https://soargbsc.com/rasp/")
abstract class RaspClient {
  factory RaspClient(Dio dio) = _RaspClient;

  @GET("current.json")
  Future<Regions> getRegions();

  @GET("{region}/{date}/status.json")
  Future<ForecastModels> getForecastModels(@Path("region") String region, @Path("date") String date);
}
