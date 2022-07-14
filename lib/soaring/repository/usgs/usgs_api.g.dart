// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usgs_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

class _UsgsClient implements UsgsClient {
  _UsgsClient(this._dio, {this.baseUrl});

  final Dio _dio;

  String? baseUrl;

  @override
  Future<NationalMap> getElevation(latitude, longitude, units) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'y': latitude,
      r'x': longitude,
      r'units': units
    };
    final _headers = <String, dynamic>{};
    final _data = <String, dynamic>{};
    final _result = await _dio.fetch<Map<String, dynamic>>(
        _setStreamType<NationalMap>(
            Options(method: 'GET', headers: _headers, extra: _extra)
                .compose(_dio.options,
                    'https://nationalmap.gov/epqs/pqs.php?output=json',
                    queryParameters: queryParameters, data: _data)
                .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = NationalMap.fromJson(_result.data!);
    return value;
  }

  RequestOptions _setStreamType<T>(RequestOptions requestOptions) {
    if (T != dynamic &&
        !(requestOptions.responseType == ResponseType.bytes ||
            requestOptions.responseType == ResponseType.stream)) {
      if (T == String) {
        requestOptions.responseType = ResponseType.plain;
      } else {
        requestOptions.responseType = ResponseType.json;
      }
    }
    return requestOptions;
  }
}
