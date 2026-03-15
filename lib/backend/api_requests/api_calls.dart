import 'dart:convert';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
const _geminiModel = 'gemini-2.5-flash';
const _geminiApiUrl =
    'https://generativelanguage.googleapis.com/v1beta/models/$_geminiModel:generateContent';

class GeminiGenerateCall {
  static Future<ApiCallResponse> call({
    String? textValue = '',
    List<Map<String, dynamic>> history = const [],
    String? systemInstruction,
  }) async {
    if (_geminiApiKey.isEmpty) {
      return ApiCallResponse(
        {
          'error': {
            'message':
                'Missing Gemini API key. Run Flutter with --dart-define=GEMINI_API_KEY=your_key',
          },
        },
        const {},
        400,
      );
    }

    final contents = <Map<String, dynamic>>[
      ...history,
      {
        'role': 'user',
        'parts': [
          {'text': textValue ?? ''}
        ],
      },
    ];

    final ffApiRequestBody = jsonEncode({
      'contents': contents,
      if ((systemInstruction ?? '').trim().isNotEmpty)
        'systemInstruction': {
          'parts': [
            {'text': systemInstruction!.trim()}
          ],
        },
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': 4096,
        'thinkingConfig': {
          'thinkingBudget': 0,
        },
      },
    });

    return ApiManager.instance.makeApiCall(
      callName: 'GeminiGenerate',
      apiUrl: _geminiApiUrl,
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _geminiApiKey,
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

  static String? geminiReplyText(dynamic response) {
    if (response is! Map<String, dynamic>) {
      return castToType<String>(
        getJsonField(
          response,
          r'''$.candidates[0].content.parts[0].text''',
        ),
      );
    }

    final candidates = response['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      return null;
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map<String, dynamic>) {
      return null;
    }

    final content = firstCandidate['content'];
    if (content is! Map<String, dynamic>) {
      return null;
    }

    final parts = content['parts'];
    if (parts is! List) {
      return null;
    }

    final textParts = parts
        .whereType<Map>()
        .map((part) => part['text'])
        .whereType<String>()
        .map((part) => part.trimRight())
        .where((part) => part.isNotEmpty)
        .toList();

    if (textParts.isEmpty) {
      return null;
    }

    return textParts.join('\n\n');
  }

  static String? errorText(dynamic response) => castToType<String>(
        getJsonField(
          response,
          r'''$.error.message''',
        ),
      );

  static String? finishReason(dynamic response) => castToType<String>(
        getJsonField(
          response,
          r'''$.candidates[0].finishReason''',
        ),
      );
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
