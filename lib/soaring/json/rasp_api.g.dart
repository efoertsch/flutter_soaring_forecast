// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rasp_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _RaspClient implements RaspClient {
  _RaspClient(this._dio) {
    ArgumentError.checkNotNull(_dio, '_dio');
  }

  final Dio _dio;

  final String baseUrl = 'https://soargbsc.com/rasp/';

  @override
  getRegions() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final Response<Map<String, dynamic>> _result = await _dio.request(
        '/current.json',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = Regions.fromJson(_result.data);
    return Future.value(value);
  }

  @override
  getForecastModels(region, date) async {
    ArgumentError.checkNotNull(region, 'region');
    ArgumentError.checkNotNull(date, 'date');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final Response<Map<String, dynamic>> _result = await _dio.request(
        '/$region/$date/status.json',
        queryParameters: queryParameters,
        options: RequestOptions(
            method: 'GET',
            headers: <String, dynamic>{},
            extra: _extra,
            baseUrl: baseUrl),
        data: _data);
    final value = ForecastModels.fromJson(_result.data);
    return Future.value(value);
  }
}
