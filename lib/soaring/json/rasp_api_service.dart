
import "dart:async";
import 'package:chopper/chopper.dart';

part 'rasp_api_service.chopper.dart';


@ChopperApi(baseUrl: "https://soargbsc.com/rasp/")
abstract class RaspApiService extends ChopperService  {

  static RaspApiService create() {
    final client = ChopperClient(
      // The first part of the URL is now here
      baseUrl: 'https://jsonplaceholder.typicode.com',
      services: [
        // The generated implementation
        _$RaspApiService(),
      ],
      interceptors: [
        // Both request & response interceptors go here
        HttpLoggingInterceptor()
      ],
      // Converts data to & from JSON and adds the application/json header.
      converter: JsonConverter(),
    );

    // The generated class with the ChopperClient passed in
    return _$RaspApiService(client);
  }


  @Get(path: 'current.json')
  Future<Response> getCurrentJson();
}
