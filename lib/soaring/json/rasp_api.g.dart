// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rasp_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _RaspClient implements RaspClient {
  _RaspClient(this._dio) {
    ArgumentError.checkNotNull(_dio, '_dio');
    _dio.options.baseUrl = 'https://soargbsc.com/rasp/';
  }

  final Dio _dio;

  @override
  getRegions() async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    const _data = null;
    final _result = await _dio.request('current.json',
        queryParameters: queryParameters,
        options: RequestOptions(method: 'GET', headers: {}, extra: _extra),
        data: _data);
    var value = Regions.fromJson(_result.data);
    return Future.value(value);
  }

  @override
  getForecastModels(region, date) async {
    ArgumentError.checkNotNull(region, 'region');
    ArgumentError.checkNotNull(date, 'date');
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    const _data = null;
    final _result = await _dio.request('/rasp/$region/$date/status.json',
        queryParameters: queryParameters,
        options: RequestOptions(method: 'GET', headers: {}, extra: _extra),
        data: _data);
    var value = ForecastModels.fromJson(_result.data);
    return Future.value(value);
  }
}
