// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'one800wxbrief_api.dart';

// **************************************************************************
// RetrofitGenerator
// **************************************************************************

// ignore_for_file: unnecessary_brace_in_string_interps,no_leading_underscores_for_local_identifiers

class _One800WxBriefClient implements One800WxBriefClient {
  _One800WxBriefClient(
    this._dio, {
    this.baseUrl,
  }) {
    baseUrl ??= 'https://lmfsweb.afss.com/Website/rest/';
  }

  final Dio _dio;

  String? baseUrl;

  @override
  Future<MetarTafResponse> getMETAR(
    basicBase64,
    airport,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'location': airport};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<MetarTafResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
            .compose(
              _dio.options,
              '/retrieveMETAR',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = MetarTafResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<MetarTafResponse> getTAF(
    basicBase64,
    airport,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'location': airport};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = <String, dynamic>{};
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<MetarTafResponse>(Options(
      method: 'GET',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
            .compose(
              _dio.options,
              '/retrieveTAF',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = MetarTafResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<RouteBriefing> getRouteBriefing(
    basicBase64,
    completeQueryString,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = completeQueryString;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<RouteBriefing>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
            .compose(
              _dio.options,
              'FP/routeBriefing',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = RouteBriefing.fromJson(_result.data!);
    return value;
  }

  @override
  Future<RouteBriefing> getAreaBriefing(
    basicBase64,
    completeQueryString,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final _data = completeQueryString;
    final _result = await _dio
        .fetch<Map<String, dynamic>>(_setStreamType<RouteBriefing>(Options(
      method: 'POST',
      headers: _headers,
      extra: _extra,
      contentType: 'application/x-www-form-urlencoded',
    )
            .compose(
              _dio.options,
              'FP/areaBriefing',
              queryParameters: queryParameters,
              data: _data,
            )
            .copyWith(baseUrl: baseUrl ?? _dio.options.baseUrl)));
    final value = RouteBriefing.fromJson(_result.data!);
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
