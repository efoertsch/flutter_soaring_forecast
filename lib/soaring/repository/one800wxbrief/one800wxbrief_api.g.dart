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
    String basicBase64,
    String airport,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'location': airport};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final Map<String, dynamic>? _data = null;
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
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = MetarTafResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<MetarTafResponse> getTAF(
    String basicBase64,
    String airport,
  ) async {
    const _extra = <String, dynamic>{};
    final queryParameters = <String, dynamic>{r'location': airport};
    final _headers = <String, dynamic>{
      r'Content-Type': 'application/x-www-form-urlencoded',
      r'User-Agent': 'Soaring Forecast FFSP Interface',
      r'Authorization': basicBase64,
    };
    _headers.removeWhere((k, v) => v == null);
    final Map<String, dynamic>? _data = null;
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
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = MetarTafResponse.fromJson(_result.data!);
    return value;
  }

  @override
  Future<One800WxBrief> getRouteBriefing(
    String basicBase64,
    String completeQueryString,
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
        .fetch<Map<String, dynamic>>(_setStreamType<One800WxBrief>(Options(
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
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = One800WxBrief.fromJson(_result.data!);
    return value;
  }

  @override
  Future<One800WxBrief> getAreaBriefing(
    String basicBase64,
    String completeQueryString,
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
        .fetch<Map<String, dynamic>>(_setStreamType<One800WxBrief>(Options(
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
            .copyWith(
                baseUrl: _combineBaseUrls(
              _dio.options.baseUrl,
              baseUrl,
            ))));
    final value = One800WxBrief.fromJson(_result.data!);
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
