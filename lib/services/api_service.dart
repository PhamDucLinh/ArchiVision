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
    required this.imageMimeType,
    required this.prompt,
    required this.rawResponse,
  });

  final Uint8List imageBytes;
  final String imageUrl;
  final String imageMimeType;
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
/// Step 1:
///   source image -> Gemini text/vision -> optimized Vietnamese prompt
/// Step 2:
///   source image + optimized prompt (+ optional style reference) ->
///   Gemini Interactions API image model -> rendered image
class ApiService {
  ApiService({
    http.Client? client,
    String? geminiApiKey,
    String? geminiTextModel,
    String? geminiImageModel,
    String? interactionsApiUrl,
    String? imageAspectRatio,
    String? imageSize,
  }) : _client = client ?? http.Client(),
       _geminiApiKey =
           geminiApiKey ??
           _resolveGeminiApiKey(
             primary: const String.fromEnvironment(
               'ARCHIVISION_GEMINI_API_KEY',
             ),
             fallback: const String.fromEnvironment('GOOGLE_API_KEY'),
           ),
       _geminiTextModel =
           geminiTextModel ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_MODEL',
             defaultValue: 'gemini-3.5-flash',
           ),
       _geminiImageModel =
           geminiImageModel ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_IMAGE_MODEL',
             defaultValue: 'gemini-3-pro-image',
           ),
       _interactionsApiUrl =
           interactionsApiUrl ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_INTERACTIONS_URL',
             defaultValue:
                 'https://generativelanguage.googleapis.com/v1beta/interactions',
           ),
       _imageAspectRatio =
           imageAspectRatio ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_IMAGE_ASPECT_RATIO',
             defaultValue: '16:9',
           ),
       _imageSize =
           imageSize ??
           const String.fromEnvironment(
             'ARCHIVISION_GEMINI_IMAGE_SIZE',
             defaultValue: '2K',
           );

  static const String analyzingMessage =
      '🤖 AI đang phân tích không gian và vật liệu...';
  static const String renderingMessage = '⚡ Đang tiến hành render phối cảnh...';

  final http.Client _client;
  final String _geminiApiKey;
  final String _geminiTextModel;
  final String _geminiImageModel;
  final String _interactionsApiUrl;
  final String _imageAspectRatio;
  final String _imageSize;

  static const List<String> _geminiTextFallbackModels = <String>[
    'gemini-3.5-flash',
    'gemini-2.5-flash',
    'gemini-flash-latest',
  ];

  static const List<String> _geminiImageFallbackModels = <String>[
    'gemini-3-pro-image',
    'gemini-3.1-flash-image',
    'gemini-2.5-flash-image',
  ];

  ApiCredentials get fallbackCredentials =>
      ApiCredentials(geminiApiKey: _geminiApiKey).trimmed();

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
    Uint8List? styleReferenceImageBytes,
    String? styleReferenceFileName,
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
        styleReferenceImageBytes: styleReferenceImageBytes,
        styleReferenceFileName: styleReferenceFileName,
        optimizedPrompt: optimizedPrompt,
        geminiApiKey: credentials.geminiApiKey,
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
            'Thiếu Gemini API key. Hãy nhập key trong app hoặc truyền --dart-define=ARCHIVISION_GEMINI_API_KEY=... khi chạy app.',
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
      _geminiTextModel,
      ..._geminiTextFallbackModels.where((model) => model != _geminiTextModel),
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
    Uint8List? styleReferenceImageBytes,
    String? styleReferenceFileName,
    required String optimizedPrompt,
    required String geminiApiKey,
  }) async {
    final normalizedGeminiApiKey = geminiApiKey.trim();
    if (normalizedGeminiApiKey.isEmpty) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details:
            'Thiếu Gemini API key. Hãy nhập key trong app trước khi render.',
        credentialKind: ApiCredentialKind.gemini,
      );
    }

    if (_interactionsApiUrl.trim().isEmpty) {
      throw const ApiServiceException(
        'Lỗi render hệ thống',
        details:
            'Thiếu endpoint Gemini Interactions API. Hãy cấu hình ARCHIVISION_GEMINI_INTERACTIONS_URL nếu cần override endpoint mặc định.',
      );
    }

    final candidateModels = <String>[
      _geminiImageModel,
      ..._geminiImageFallbackModels.where(
        (model) => model != _geminiImageModel,
      ),
    ];

    ApiServiceException? lastModelError;

    for (final modelName in candidateModels) {
      final payload = _buildGeminiImagePayload(
        modelName: modelName,
        sourceImageBytes: imageBytes,
        sourceFileName: sourceFileName,
        styleReferenceImageBytes: styleReferenceImageBytes,
        styleReferenceFileName: styleReferenceFileName,
        optimizedPrompt: optimizedPrompt,
      );

      try {
        final response = await _client.post(
          Uri.parse(_interactionsApiUrl),
          headers: <String, String>{
            'x-goog-api-key': normalizedGeminiApiKey,
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(payload),
        );

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw ApiServiceException(
            'Lỗi render hệ thống',
            details:
                'Gemini image API từ chối request (${response.statusCode}): ${_extractErrorMessage(response.body)}',
            credentialKind: ApiCredentialKind.gemini,
          );
        }

        if (response.statusCode == 404 &&
            _looksLikeMissingGeminiModel(response.body)) {
          lastModelError = ApiServiceException(
            'Lỗi render hệ thống',
            details:
                'Gemini image model `$modelName` chưa khả dụng. Đã thử chuyển sang model fallback.',
          );
          continue;
        }

        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ApiServiceException(
            'Lỗi render hệ thống',
            details:
                'Gemini image API failed (${response.statusCode}): ${_extractErrorMessage(response.body)}',
          );
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          throw const ApiServiceException(
            'Lỗi render hệ thống',
            details:
                'Gemini image API trả về dữ liệu không đúng định dạng JSON object.',
          );
        }

        final renderAsset = await _extractRenderAsset(decoded);
        return ArchitectureGenerationResult(
          imageBytes: renderAsset.bytes,
          imageUrl: renderAsset.url,
          imageMimeType: renderAsset.mimeType,
          prompt: optimizedPrompt,
          rawResponse: decoded,
        );
      } on ApiServiceException catch (error) {
        final canRetryWithFallback =
            _looksLikeMissingGeminiModel(error.details ?? '') &&
            modelName != candidateModels.last;
        if (canRetryWithFallback) {
          lastModelError = error;
          continue;
        }
        rethrow;
      } catch (error) {
        throw ApiServiceException(
          'Lỗi render hệ thống',
          details: error.toString(),
        );
      }
    }

    throw lastModelError ??
        const ApiServiceException(
          'Lỗi render hệ thống',
          details: 'Không tìm thấy Gemini image model khả dụng để render ảnh.',
        );
  }

  Map<String, dynamic> _buildGeminiImagePayload({
    required String modelName,
    required Uint8List sourceImageBytes,
    required String sourceFileName,
    Uint8List? styleReferenceImageBytes,
    String? styleReferenceFileName,
    required String optimizedPrompt,
  }) {
    final input = <Map<String, String>>[
      <String, String>{
        'type': 'text',
        'text': _buildGeminiImagePrompt(
          optimizedPrompt: optimizedPrompt,
          hasStyleReference: styleReferenceImageBytes != null,
        ),
      },
      <String, String>{
        'type': 'image',
        'mime_type': _mimeTypeFromFileName(sourceFileName),
        'data': base64Encode(sourceImageBytes),
      },
    ];

    if (styleReferenceImageBytes != null) {
      input.add(<String, String>{
        'type': 'image',
        'mime_type': _mimeTypeFromFileName(
          styleReferenceFileName ?? 'style-reference.png',
        ),
        'data': base64Encode(styleReferenceImageBytes),
      });
    }

    return <String, dynamic>{
      'model': modelName,
      'input': input,
      'response_format': <String, String>{
        'type': 'image',
        'mime_type': 'image/jpeg',
        'aspect_ratio': _imageAspectRatio,
        'image_size': _imageSize,
      },
      'store': false,
    };
  }

  Future<_RenderAsset> _extractRenderAsset(Map<String, dynamic> payload) async {
    final remoteUrl = _extractImageUrl(payload);
    final inlineDataUrl = _extractInlineDataUrl(payload);
    final encodedImage = _extractBase64Image(payload);
    final outputImageMimeType =
        _readPath(payload, ['output_image', 'mime_type']) as String?;

    if (encodedImage != null) {
      final bytes = _decodeBase64Image(encodedImage);
      return _RenderAsset(
        bytes: bytes,
        mimeType: outputImageMimeType ?? 'image/jpeg',
        url:
            inlineDataUrl ??
            _buildInlineDataUrlFromBytes(
              bytes,
              mimeType: outputImageMimeType ?? 'image/jpeg',
            ),
      );
    }

    if (inlineDataUrl != null) {
      final bytes = _decodeDataUrl(inlineDataUrl);
      return _RenderAsset(
        bytes: bytes,
        url: inlineDataUrl,
        mimeType: _mimeTypeFromDataUrl(inlineDataUrl) ?? 'image/jpeg',
      );
    }

    if (remoteUrl != null) {
      final bytes = await _downloadImageBytes(remoteUrl);
      return _RenderAsset(
        bytes: bytes,
        url: remoteUrl,
        mimeType: outputImageMimeType ?? _mimeTypeFromFileName(remoteUrl),
      );
    }

    throw const ApiServiceException(
      'Lỗi render hệ thống',
      details:
          'Gemini image API đã phản hồi nhưng không tìm thấy ảnh output ở các field base64/URL phổ biến.',
    );
  }

  String? _extractBase64Image(Map<String, dynamic> payload) {
    final looseImageEntry = _readPath(payload, ['images', 0]);
    final candidates = <String?>[
      _readPath(payload, ['output_image', 'data']) as String?,
      _readPath(payload, ['output', 0, 'data']) as String?,
      _readPath(payload, ['output', 0, 'image', 'data']) as String?,
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
      _readPath(payload, ['output_image', 'url']) as String?,
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
      _readPath(payload, ['output_image', 'image_url']) as String?,
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

        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message;
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

  String _buildGeminiImagePrompt({
    required String optimizedPrompt,
    required bool hasStyleReference,
  }) {
    final parts = <String>[
      optimizedPrompt.trim(),
      'Giữ nguyên cấu trúc hình khối, tỷ lệ mặt đứng và bố cục camera của ảnh gốc.',
      'Render ra đúng 1 ảnh phối cảnh kiến trúc photorealistic chất lượng cao.',
      if (hasStyleReference)
        'Dùng ảnh tham chiếu cuối cùng chỉ để học phong cách vật liệu, màu sắc, mood và chi tiết hoàn thiện. Không sao chép hình khối hay bố cục từ ảnh tham chiếu.',
    ];

    return parts.join('\n');
  }

  String _buildInlineDataUrlFromBytes(
    Uint8List bytes, {
    required String mimeType,
  }) {
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  String? _mimeTypeFromDataUrl(String dataUrl) {
    if (!dataUrl.startsWith('data:')) {
      return null;
    }

    final semicolonIndex = dataUrl.indexOf(';');
    if (semicolonIndex <= 5) {
      return null;
    }

    return dataUrl.substring(5, semicolonIndex);
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
      normalized.contains('model not found') ||
      normalized.contains('unsupported model') ||
      normalized.contains('not found') ||
      normalized.contains('404');
}

class _RenderAsset {
  const _RenderAsset({
    required this.bytes,
    required this.url,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String url;
  final String mimeType;
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
