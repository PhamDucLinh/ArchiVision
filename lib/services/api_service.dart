import 'dart:convert';
import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

import 'api_credentials_store.dart';

typedef ArchitectureChainStatusCallback = void Function(String message);

enum BuildingType {
  hotel('Khách sạn', 'Hotel'),
  office('Văn phòng', 'Office Building'),
  apartment('Chung cư', 'Apartment Complex'),
  gardenHouse('Nhà vườn', 'Garden House'),
  townhouse('Nhà phố', 'Townhouse'),
  villa('Biệt thự', 'Villa');

  const BuildingType(this.labelVi, this.promptLabelEn);

  final String labelVi;
  final String promptLabelEn;
}

enum ArchitectureStyle {
  modern('Hiện đại', 'Modern'),
  minimalism('Tối giản', 'Minimalist'),
  neoclassical('Tân cổ điển', 'Neoclassical'),
  indochine('Indochine', 'Indochine'),
  tropical('Nhiệt đới (Tropical)', 'Tropical'),
  industrial('Công nghiệp (Industrial)', 'Industrial');

  const ArchitectureStyle(this.labelVi, this.promptLabelEn);

  final String labelVi;
  final String promptLabelEn;
}

enum LightingCondition {
  daytime('Ban ngày', 'daytime lighting'),
  sunset('Hoàng hôn', 'sunset lighting'),
  night('Ban đêm', 'night lighting'),
  warmInterior('Ánh sáng nội thất ấm áp', 'warm interior lighting');

  const LightingCondition(this.labelVi, this.promptLabelEn);

  final String labelVi;
  final String promptLabelEn;
}

enum AiProvider { openAiCompatible, controlNetCompatible }

class ArchitectureFilters {
  const ArchitectureFilters({
    required this.buildingType,
    required this.style,
    required this.lighting,
  });

  final BuildingType buildingType;
  final ArchitectureStyle style;
  final LightingCondition lighting;

  String toEnglishPrompt({String customPrompt = ''}) {
    final basePrompt =
        'A photorealistic architectural rendering of a '
        '${buildingType.promptLabelEn}, '
        '${style.promptLabelEn} style, '
        '${lighting.promptLabelEn}, highly detailed, 8k resolution, '
        'maintaining the original structure of the input image.';

    final trimmedPrompt = customPrompt.trim();
    if (trimmedPrompt.isEmpty) {
      return basePrompt;
    }

    return '$basePrompt Additional client requirements: '
        '${_normalizePromptSentence(trimmedPrompt)}';
  }
}

class ArchitectureGenerationResult {
  const ArchitectureGenerationResult({
    required this.imageBytes,
    required this.imageUrl,
    required this.prompt,
    required this.rawResponse,
  });

  final Uint8List imageBytes;
  final String imageUrl;
  final String prompt;
  final Map<String, dynamic> rawResponse;

  String get optimizedPrompt => prompt;
}

class ApiServiceException implements Exception {
  const ApiServiceException(
    this.userMessage, {
    this.details,
    this.credentialKind,
  });

  final String userMessage;
  final String? details;
  final ApiCredentialKind? credentialKind;

  @override
  String toString() {
    final details = this.details?.trim();
    if (details == null || details.isEmpty) {
      return userMessage;
    }
    return '$userMessage\n$details';
  }
}

/// Core API layer for the architecture render workflow.
///
/// Note: the app targets Desktop and Web, so this service works with raw image
/// bytes + file name instead of `dart:io File` to stay web-compatible.
class ApiService {
  ApiService({
    http.Client? client,
    String? apiUrl,
    String? apiKey,
    String? geminiApiKey,
    String? geminiModel,
    AiProvider? provider,
  }) : _client = client ?? http.Client(),
       _provider = provider ?? _providerFromEnvironment(),
       _apiUrl =
           apiUrl ?? _defaultApiUrl(provider ?? _providerFromEnvironment()),
       _apiKey = apiKey ?? const String.fromEnvironment('ARCHIVISION_API_KEY'),
       _geminiApiKey =
           geminiApiKey ??
           _resolveGeminiApiKey(
             primary: const String.fromEnvironment(
               'ARCHIVISION_GEMINI_API_KEY',
             ),
             fallback: const String.fromEnvironment('GOOGLE_API_KEY'),
           ),
       _geminiModel =
           geminiModel ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_MODEL',
             defaultValue: 'gemini-3.5-flash',
           );

  static const String analyzingMessage =
      '🤖 AI đang phân tích không gian và vật liệu...';
  static const String renderingMessage = '⚡ Đang tiến hành render phối cảnh...';

  final http.Client _client;
  final AiProvider _provider;
  final String _apiUrl;
  final String _apiKey;
  final String _geminiApiKey;
  final String _geminiModel;
  static const List<String> _geminiFallbackModels = <String>[
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  ApiCredentials get fallbackCredentials => ApiCredentials(
    geminiApiKey: _geminiApiKey,
    renderApiKey: _apiKey,
  ).trimmed();

  Future<String> optimizeArchitecturePrompt({
    required Uint8List sourceImageBytes,
    required String sourceFileName,
    required BuildingType buildingType,
    required ArchitectureStyle style,
    required LightingCondition lighting,
    required String context,
    required String geminiApiKey,
  }) async {
    return analyzeAndBuildPrompt(
      imageBytes: sourceImageBytes,
      imageMimeType: _mimeTypeFromFileName(sourceFileName),
      buildingType: buildingType.labelVi,
      style: style.labelVi,
      context: context,
      lighting: lighting.labelVi,
      geminiApiKey: geminiApiKey,
    );
  }

  Future<ArchitectureGenerationResult> generateArchitecture({
    required Uint8List sourceImageBytes,
    required String sourceFileName,
    required BuildingType buildingType,
    required ArchitectureStyle style,
    required LightingCondition lighting,
    required String context,
    required ApiCredentials credentials,
    ArchitectureChainStatusCallback? onStatusChanged,
  }) async {
    try {
      onStatusChanged?.call(analyzingMessage);
      final optimizedPrompt = await optimizeArchitecturePrompt(
        sourceImageBytes: sourceImageBytes,
        sourceFileName: sourceFileName,
        buildingType: buildingType,
        style: style,
        lighting: lighting,
        context: context,
        geminiApiKey: credentials.geminiApiKey,
      );

      onStatusChanged?.call(renderingMessage);
      return await generateArchitectureImage(
        imageBytes: sourceImageBytes,
        sourceFileName: sourceFileName,
        optimizedPrompt: optimizedPrompt,
        renderApiKey: credentials.renderApiKey,
      );
    } on ApiServiceException {
      rethrow;
    } catch (error) {
      throw ApiServiceException(
        'Lỗi render hệ thống',
        details: 'Unexpected pipeline failure: $error',
      );
    }
  }

  Future<String> analyzeAndBuildPrompt({
    required Uint8List imageBytes,
    required String imageMimeType,
    required String buildingType,
    required String style,
    required String context,
    required String lighting,
    required String geminiApiKey,
  }) async {
    final normalizedGeminiApiKey = geminiApiKey.trim();
    if (normalizedGeminiApiKey.isEmpty) {
      throw const ApiServiceException(
        'Không thể phân tích ảnh',
        details:
            'Thiếu ARCHIVISION_GEMINI_API_KEY hoặc GOOGLE_API_KEY để gọi Gemini 1.5 Flash.',
        credentialKind: ApiCredentialKind.gemini,
      );
    }

    final systemPrompt = _buildGeminiSystemPrompt(
      buildingType: buildingType,
      style: style,
      context: context,
      lighting: lighting,
    );

    try {
      return await _generatePromptWithGemini(
        imageBytes: imageBytes,
        imageMimeType: imageMimeType,
        normalizedGeminiApiKey: normalizedGeminiApiKey,
        systemPrompt: systemPrompt,
      );
    } on InvalidApiKey catch (error) {
      throw ApiServiceException(
        'Không thể phân tích ảnh',
        details: error.toString(),
        credentialKind: ApiCredentialKind.gemini,
      );
    } on UnsupportedUserLocation catch (error) {
      throw ApiServiceException(
        'Không thể phân tích ảnh',
        details: error.toString(),
      );
    } on ServerException catch (error) {
      throw ApiServiceException(
        'Không thể phân tích ảnh',
        details: error.toString(),
      );
    } on GenerativeAIException catch (error) {
      throw ApiServiceException(
        'Không thể phân tích ảnh',
        details: error.toString(),
      );
    } catch (error) {
      if (error is ApiServiceException) {
        rethrow;
      }
      throw ApiServiceException(
        'Không thể phân tích ảnh',
        details: error.toString(),
      );
    }
  }

  Future<String> _generatePromptWithGemini({
    required Uint8List imageBytes,
    required String imageMimeType,
    required String normalizedGeminiApiKey,
    required String systemPrompt,
  }) async {
    final candidateModels = <String>[
      _geminiModel,
      ..._geminiFallbackModels.where((model) => model != _geminiModel),
    ];

    ApiServiceException? lastModelError;

    for (final modelName in candidateModels) {
      final model = GenerativeModel(
        model: modelName,
        apiKey: normalizedGeminiApiKey,
        systemInstruction: Content.system(systemPrompt),
      );

      try {
        final response = await model.generateContent([
          Content.multi([
            DataPart(imageMimeType, imageBytes),
            TextPart(
              'Hãy trả về đúng 1 đoạn prompt tiếng Việt hoàn chỉnh để dùng cho AI Render.',
            ),
          ]),
        ]);

        final optimizedPrompt = response.text?.trim();
        if (optimizedPrompt == null || optimizedPrompt.isEmpty) {
          throw const ApiServiceException(
            'Không thể phân tích ảnh',
            details: 'Gemini trả về nội dung rỗng.',
          );
        }

        return optimizedPrompt;
      } on InvalidApiKey {
        rethrow;
      } on UnsupportedUserLocation {
        rethrow;
      } on GenerativeAIException catch (error) {
        if (_looksLikeMissingGeminiModel(error.toString())) {
          lastModelError = ApiServiceException(
            'Không thể phân tích ảnh',
            details:
                'Gemini model `$modelName` không còn hỗ trợ generateContent. '
                'Đã thử chuyển sang model khác.',
          );
          continue;
        }
        rethrow;
      } on ApiServiceException {
        rethrow;
      }
    }

    throw lastModelError ??
        const ApiServiceException(
          'Không thể phân tích ảnh',
          details: 'Không tìm thấy Gemini model khả dụng để tối ưu prompt.',
        );
  }

  Future<ArchitectureGenerationResult> generateArchitectureImage({
    required Uint8List imageBytes,
    required String sourceFileName,
    required String optimizedPrompt,
    required String renderApiKey,
  }) async {
    final normalizedRenderApiKey = renderApiKey.trim();
    if (_apiUrl.trim().isEmpty) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details:
            'Thiếu ARCHIVISION_API_URL. Hãy truyền --dart-define=ARCHIVISION_API_URL=... khi chạy app.',
      );
    }

    if (normalizedRenderApiKey.isEmpty) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details:
            'Thiếu ARCHIVISION_API_KEY. Hãy truyền --dart-define=ARCHIVISION_API_KEY=... để gọi hệ thống render.',
        credentialKind: ApiCredentialKind.render,
      );
    }

    final base64Image = base64Encode(imageBytes);
    final payload = _buildPayload(
      prompt: optimizedPrompt,
      base64Image: base64Image,
      sourceFileName: sourceFileName,
    );

    try {
      final response = await _client.post(
        Uri.parse(_apiUrl),
        headers: <String, String>{
          'Authorization': 'Bearer $normalizedRenderApiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiServiceException(
          'Lỗi render hệ thống',
          details:
              'Render API failed (${response.statusCode}): ${_extractErrorMessage(response.body)}',
          credentialKind:
              response.statusCode == 401 || response.statusCode == 403
              ? ApiCredentialKind.render
              : null,
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const ApiServiceException(
          'Lỗi render hệ thống',
          details:
              'Render API trả về dữ liệu không đúng định dạng JSON object.',
        );
      }

      final renderAsset = await _extractRenderAsset(decoded);

      return ArchitectureGenerationResult(
        imageBytes: renderAsset.bytes,
        imageUrl: renderAsset.url,
        prompt: optimizedPrompt,
        rawResponse: decoded,
      );
    } on ApiServiceException {
      rethrow;
    } catch (error) {
      throw ApiServiceException(
        'Lỗi render hệ thống',
        details: error.toString(),
      );
    }
  }

  Map<String, dynamic> _buildPayload({
    required String prompt,
    required String base64Image,
    required String sourceFileName,
  }) {
    switch (_provider) {
      case AiProvider.openAiCompatible:
        return <String, dynamic>{
          'model': const String.fromEnvironment(
            'ARCHIVISION_OPENAI_MODEL',
            defaultValue: 'gpt-image-2',
          ),
          'images': <Map<String, String>>[
            <String, String>{
              'image_url': _buildDataUrl(
                base64Image: base64Image,
                sourceFileName: sourceFileName,
              ),
            },
          ],
          'prompt': prompt,
          'input_fidelity': 'high',
          'size': '1536x1024',
          'quality': 'high',
          'output_format': 'png',
          'moderation': 'auto',
          'n': 1,
        };
      case AiProvider.controlNetCompatible:
        return <String, dynamic>{
          'prompt': prompt,
          'negative_prompt':
              'low resolution, blurry, distorted geometry, duplicated facade elements',
          'image': base64Image,
          'controlnet': <String, dynamic>{
            'enabled': true,
            'mode': 'balanced',
            'conditioning_scale': 0.9,
          },
          'image_strength': 0.35,
          'cfg_scale': 7,
          'steps': 30,
          'width': 1536,
          'height': 1024,
          'output_format': 'png',
          'response_format': 'b64_json',
          'metadata': <String, dynamic>{
            'source_file_name': sourceFileName,
            'workflow': 'architecture-image-to-image',
          },
        };
    }
  }

  Future<_RenderAsset> _extractRenderAsset(Map<String, dynamic> payload) async {
    final remoteUrl = _extractImageUrl(payload);
    final inlineDataUrl = _extractInlineDataUrl(payload);
    final encodedImage = _extractBase64Image(payload);

    if (encodedImage != null) {
      final bytes = _decodeBase64Image(encodedImage);
      return _RenderAsset(
        bytes: bytes,
        url: inlineDataUrl ?? _buildInlineDataUrlFromBytes(bytes),
      );
    }

    if (inlineDataUrl != null) {
      final bytes = _decodeDataUrl(inlineDataUrl);
      return _RenderAsset(bytes: bytes, url: inlineDataUrl);
    }

    if (remoteUrl != null) {
      final bytes = await _downloadImageBytes(remoteUrl);
      return _RenderAsset(bytes: bytes, url: remoteUrl);
    }

    throw const ApiServiceException(
      'Lỗi render hệ thống',
      details:
          'API đã phản hồi nhưng không tìm thấy ảnh output ở các field base64/URL phổ biến.',
    );
  }

  String? _extractBase64Image(Map<String, dynamic> payload) {
    final looseImageEntry = _readPath(payload, ['images', 0]);
    final candidates = <String?>[
      _readPath(payload, ['data', 0, 'b64_json']) as String?,
      _readPath(payload, ['images', 0, 'b64_json']) as String?,
      _readPath(payload, ['artifacts', 0, 'base64']) as String?,
      _readPath(payload, ['output', 0, 'content', 0, 'b64_json']) as String?,
      _readPath(payload, ['image_base64']) as String?,
      if (looseImageEntry is String &&
          !_looksLikeUrl(looseImageEntry) &&
          !looseImageEntry.startsWith('data:'))
        looseImageEntry,
    ];

    return _firstNonEmpty(candidates);
  }

  String? _extractImageUrl(Map<String, dynamic> payload) {
    final looseImageEntry = _readPath(payload, ['images', 0]);
    final candidates = <String?>[
      _readPath(payload, ['data', 0, 'url']) as String?,
      _readPath(payload, ['images', 0, 'url']) as String?,
      _readPath(payload, ['artifacts', 0, 'url']) as String?,
      _readPath(payload, ['output', 0, 'url']) as String?,
      _readPath(payload, ['image_url']) as String?,
      if (looseImageEntry is String && _looksLikeUrl(looseImageEntry))
        looseImageEntry,
    ];

    return _firstNonEmpty(candidates);
  }

  String? _extractInlineDataUrl(Map<String, dynamic> payload) {
    final looseImageEntry = _readPath(payload, ['images', 0]);
    final candidates = <String?>[
      _readPath(payload, ['data', 0, 'image_url']) as String?,
      _readPath(payload, ['images', 0, 'image_url']) as String?,
      if (looseImageEntry is String && looseImageEntry.startsWith('data:'))
        looseImageEntry,
    ];

    final value = _firstNonEmpty(candidates);
    if (value == null || !value.startsWith('data:')) {
      return null;
    }
    return value;
  }

  Object? _readPath(Object? node, List<Object> path) {
    Object? current = node;

    for (final segment in path) {
      if (segment is String && current is Map<String, dynamic>) {
        current = current[segment];
      } else if (segment is int &&
          current is List &&
          current.length > segment) {
        current = current[segment];
      } else {
        return null;
      }
    }

    return current;
  }

  Uint8List _decodeBase64Image(String encodedImage) {
    try {
      return base64Decode(encodedImage);
    } catch (_) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details: 'Không thể giải mã ảnh base64 từ phản hồi API.',
      );
    }
  }

  Uint8List _decodeDataUrl(String dataUrl) {
    final commaIndex = dataUrl.indexOf(',');
    if (commaIndex < 0 || commaIndex == dataUrl.length - 1) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details: 'Data URL trả về từ API không hợp lệ.',
      );
    }
    return _decodeBase64Image(dataUrl.substring(commaIndex + 1));
  }

  Future<Uint8List> _downloadImageBytes(String imageUrl) async {
    final response = await _client.get(
      Uri.parse(imageUrl),
      headers: const <String, String>{'Accept': 'image/*'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiServiceException(
        'Lỗi render hệ thống',
        details:
            'Không thể tải ảnh từ URL render (${response.statusCode}): $imageUrl',
      );
    }

    return response.bodyBytes;
  }

  String _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message;
          }
        }
      }
    } catch (_) {
      // Fall back to raw body below.
    }

    final compact = body.trim();
    return compact.isEmpty ? 'Không có nội dung lỗi từ server.' : compact;
  }

  String _buildGeminiSystemPrompt({
    required String buildingType,
    required String style,
    required String context,
    required String lighting,
  }) {
    final normalizedContext = context.trim().isEmpty
        ? 'Tự đề xuất bối cảnh phù hợp với loại công trình và phong cách đã chọn.'
        : context.trim();

    return '''
Bạn là Kiến trúc sư trưởng và chuyên gia diễn họa 3D. Nhiệm vụ của bạn là nhìn vào bức ảnh đính kèm, phân tích hình khối, sau đó kết hợp với các yêu cầu sau đây để viết ra 1 câu prompt tiếng Việt duy nhất dùng cho AI Render:
- Loại công trình: $buildingType
- Phong cách: $style
- Bối cảnh: $normalizedContext
- Ánh sáng: $lighting
TUYỆT ĐỐI không in ra quá trình phân tích, không chào hỏi. Chỉ in ra đúng 1 đoạn prompt tiếng Việt mô tả chi tiết vật liệu, hình khối (giữ nguyên cấu trúc ảnh gốc), bối cảnh, ánh sáng và các thông số camera chuyên dụng (tilt-shift, full-frame, f/8, ISO 100).
''';
  }

  String _buildDataUrl({
    required String base64Image,
    required String sourceFileName,
  }) {
    return 'data:${_mimeTypeFromFileName(sourceFileName)};base64,$base64Image';
  }

  String _buildInlineDataUrlFromBytes(Uint8List bytes) {
    return 'data:image/png;base64,${base64Encode(bytes)}';
  }

  String _mimeTypeFromFileName(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/png';
  }

  void dispose() {
    _client.close();
  }

  static AiProvider _providerFromEnvironment() {
    final raw = const String.fromEnvironment(
      'ARCHIVISION_AI_PROVIDER',
      defaultValue: 'openai',
    ).toLowerCase();

    return raw == 'openai'
        ? AiProvider.openAiCompatible
        : AiProvider.controlNetCompatible;
  }

  static String _defaultApiUrl(AiProvider provider) {
    return switch (provider) {
      AiProvider.openAiCompatible => 'https://api.openai.com/v1/images/edits',
      AiProvider.controlNetCompatible =>
        'https://api.example.com/v1/controlnet/image-to-image',
    };
  }

  static String _resolveGeminiApiKey({
    required String primary,
    required String fallback,
  }) {
    if (primary.trim().isNotEmpty) {
      return primary;
    }
    return fallback;
  }
}

bool _looksLikeMissingGeminiModel(String error) {
  final normalized = error.toLowerCase();
  return normalized.contains('is not found for api version') ||
      normalized.contains('is not supported for generatecontent') ||
      normalized.contains('404');
}

class _RenderAsset {
  const _RenderAsset({required this.bytes, required this.url});

  final Uint8List bytes;
  final String url;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    if (value != null && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}

bool _looksLikeUrl(String value) {
  return value.startsWith('http://') || value.startsWith('https://');
}

String _normalizePromptSentence(String prompt) {
  final trimmed = prompt.trim();
  if (trimmed.endsWith('.') || trimmed.endsWith('!') || trimmed.endsWith('?')) {
    return trimmed;
  }
  return '$trimmed.';
}
