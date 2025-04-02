// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rasp_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers,unused_element,unnecessary_string_interpolations

class _RaspClient implements RaspClient {
  _RaspClient(
    this._dio, {
    this.baseUrl,
    this.errorLogger,
  }) {
    baseUrl ??= 'https://www.soargbsc.net/rasp/';
  }

  final Dio _dio;

  String? baseUrl;

  final ParseErrorLogger? errorLogger;

  @override
  Future<Regions> getRegions() async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<Regions>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/current.json',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late Regions _value;
    try {
      _value = Regions.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<ForecastModels> getForecastModels(
    String region,
    String date,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{};
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<ForecastModels>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
    )
        .compose(
          _dio.options,
          '/${region}/${date}/status.json',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<Map<String, dynamic>>(_options);
    late ForecastModels _value;
    try {
      _value = ForecastModels.fromJson(_result.data!);
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    return _value;
  }

  @override
  Future<HttpResponse<dynamic>> getLatLongPointForecast(
    String contentType,
    String region,
    String date,
    String model,
    String time,
    String lat,
    String lon,
    String forecasts,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{r'Content-Type': contentType};
    _headers.removeWhere((k, v) => v == null);
    final _data = {
      'region': region,
      'date': date,
      'model': model,
      'time': time,
      'lat': lat,
      'lon': lon,
      'param': forecasts,
    };
    final _options = _setStreamType<HttpResponse<dynamic>>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: contentType,
    )
        .compose(
          _dio.options,
          '/cgi/get_rasp_blipspot.cgi',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch(_options);
    final _value = _result.data;
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<String>> getDaysForecastForLatLong(
    String contentType,
    String region,
    String date,
    String model,
    String time,
    String lat,
    String lon,
    String forecasts,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'region': region,
      r'date': date,
      r'model': model,
      r'time': time,
      r'lat': lat,
      r'lon': lon,
      r'param': forecasts,
    };
    final _headers = <String, dynamic>{r'Content-Type': contentType};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<String>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: contentType,
    )
        .compose(
          _dio.options,
          '/cgi/get_multirasp_blipspot.cgi',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<String>(_options);
    late String _value;
    try {
      _value = _result.data!;
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
  }

  @override
  Future<HttpResponse<String>> getEstimatedFlightAverages(
    String contentType,
    String region,
    String date,
    String model,
    String grid,
    String time,
    String glider,
    double polarFactor,
    String polarCoefficients,
    double thermalSinkRate,
    double thermalMultipler,
    String latlons,
  ) async {
    final _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{
      r'region': region,
      r'date': date,
      r'model': model,
      r'grid': grid,
      r'time': time,
      r'glider': glider,
      r'polarFactor': polarFactor,
      r'polarCoefficients': polarCoefficients,
      r'tsink': thermalSinkRate,
      r'tmult': thermalMultipler,
      r'turnpts': latlons,
    };
    final _headers = <String, dynamic>{r'Content-Type': contentType};
    _headers.removeWhere((k, v) => v == null);
    const Map<String, dynamic>? _data = null;
    final _options = _setStreamType<HttpResponse<String>>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: contentType,
    )
        .compose(
          _dio.options,
          '/cgi/get_estimated_flight_avg.cgi',
          queryParameters: queryParameters,
          data: _data,
        )
        .copyWith(
            baseUrl: _combineBaseUrls(
          _dio.options.baseUrl,
          baseUrl,
        )));
    final _result = await _dio.fetch<String>(_options);
    late String _value;
    try {
      _value = _result.data!;
    } on Object catch (e, s) {
      errorLogger?.logError(e, s, _options);
      rethrow;
    }
    final httpResponse = HttpResponse(_value, _result);
    return httpResponse;
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

  String _combineBaseUrls(
    String dioBaseUrl,
    String? baseUrl,
  ) {
    if (baseUrl == null || baseUrl.trim().isEmpty) {
      return dioBaseUrl;
    }

    final url = Uri.parse(baseUrl);

    if (url.isAbsolute) {
      return url.toString();
    }

    return Uri.parse(dioBaseUrl).resolveUri(url).toString();
  }
}
