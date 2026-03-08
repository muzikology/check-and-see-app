import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';
const _scanAnalyzeFunctionUrl = String.fromEnvironment(
  'SCAN_ANALYZE_FUNCTION_URL',
  defaultValue:
      'https://us-central1-ai-health-scanner-5e3b9.cloudfunctions.net/analyzeProductScan',
);

class OpenAIVisionScanCall {
  static Future<ApiCallResponse> call({
    required String imageDataUrl,
    Map<String, dynamic>? profile,
  }) async {
    final ffApiRequestBody = jsonEncode({
      'imageDataUrl': imageDataUrl,
      'profile': profile ?? {},
    });

    return ApiManager.instance.makeApiCall(
      callName: 'Analyze Product Scan',
      apiUrl: _scanAnalyzeFunctionUrl,
      callType: ApiCallType.POST,
      headers: {
        'Authorization': currentJwtToken.isNotEmpty
            ? 'Bearer $currentJwtToken'
            : '',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  if (item is DocumentReference) {
    return item.path;
  }
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
