import 'dart:async';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:super_clipboard/super_clipboard.dart';

import 'services/api_credentials_store.dart';
import 'services/api_service.dart';

const _kBackgroundColor = Color(0xFF131313);
const _kShellBorderColor = Color(0xFF7E7AFF);
const _kPanelColor = Color(0xFF1C1B1B);
const _kPanelColorDeep = Color(0xFF171717);
const _kSurfaceColor = Color(0xFF1A1A1A);
const _kOutlineColor = Color(0xFF2D2D2D);
const _kOutlineSoftColor = Color(0xFF444748);
const _kMutedTextColor = Color(0xFF8E9192);
const _kDashedColor = Color(0xFF64748B);
const _kAccentColor = Color(0xFF465472);
const _kSuccessColor = Color(0xFF6ECF92);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArchiVisionApp());
}

class ArchiVisionApp extends StatelessWidget {
  const ArchiVisionApp({super.key, this.apiService, this.credentialsStore});

  final ApiService? apiService;
  final ApiCredentialsStore? credentialsStore;

  @override
  Widget build(BuildContext context) {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Colors.white,
      onPrimary: Color(0xFF121212),
      secondary: Color(0xFFBCC7DE),
      onSecondary: Color(0xFF263143),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: _kBackgroundColor,
      onSurface: Color(0xFFE5E2E1),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArchiVision Studio',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _kBackgroundColor,
        canvasColor: _kBackgroundColor,
        dividerColor: _kOutlineSoftColor,
        textTheme: ThemeData.dark().textTheme.copyWith(
          headlineLarge: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
          ),
          headlineMedium: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
          titleLarge: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          titleMedium: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          bodyLarge: const TextStyle(fontSize: 16, height: 1.5),
          bodyMedium: const TextStyle(fontSize: 14, height: 1.5),
          bodySmall: const TextStyle(fontSize: 12, height: 1.45),
          labelLarge: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          labelMedium: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: _kSurfaceColor,
          hintStyle: const TextStyle(color: _kMutedTextColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kOutlineColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: _kOutlineColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.white),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.14),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.38),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            elevation: 0,
            foregroundColor: Colors.white,
            side: const BorderSide(color: _kOutlineColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        splashFactory: NoSplash.splashFactory,
      ),
      home: ArchiVisionStudioPage(
        apiService: apiService ?? ApiService(),
        credentialsStore: credentialsStore ?? SecureApiCredentialsStore(),
      ),
    );
  }
}

enum StudioViewState { idle, loading, success }

enum ContextPreset {
  urbanStreet('Đường phố Việt Nam'),
  luxuryCompound('Khu đô thị cao cấp'),
  tropicalGarden('Sân vườn nhiệt đới'),
  coastalResort('Khu nghỉ dưỡng ven biển'),
  hillsideRetreat('Đồi cây xanh');

  const ContextPreset(this.labelVi);

  final String labelVi;
}

enum CameraAnglePreset {
  wide('Góc rộng'),
  eyeLevel('Tầm mắt'),
  aerial('Flycam 3/4'),
  heroFacade('Hero facade');

  const CameraAnglePreset(this.labelVi);

  final String labelVi;
}

class ArchiVisionStudioPage extends StatefulWidget {
  const ArchiVisionStudioPage({
    super.key,
    required this.apiService,
    required this.credentialsStore,
  });

  final ApiService apiService;
  final ApiCredentialsStore credentialsStore;

  @override
  State<ArchiVisionStudioPage> createState() => _ArchiVisionStudioPageState();
}

class _ArchiVisionStudioPageState extends State<ArchiVisionStudioPage> {
  late final ArchitectureStudioController _controller;
  bool _isCredentialDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _controller = ArchitectureStudioController(
      apiService: widget.apiService,
      credentialsStore: widget.credentialsStore,
    );
    unawaited(_initializeController());

    if (kIsWeb) {
      ClipboardEvents.instance?.registerPasteEventListener(_onWebPasteEvent);
    }
  }

  @override
  void dispose() {
    if (kIsWeb) {
      ClipboardEvents.instance?.unregisterPasteEventListener(_onWebPasteEvent);
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeController() async {
    await _controller.initialize();
    if (!mounted) {
      return;
    }
    await _presentCredentialDialogIfNeeded();
  }

  Future<void> _onWebPasteEvent(ClipboardReadEvent event) async {
    final reader = await event.getClipboardReader();
    await _controller.pasteImageFromClipboard(reader: reader);
  }

  Future<void> _handlePasteShortcut() async {
    await _controller.pasteImageFromClipboard();
  }

  Future<void> _presentCredentialDialogIfNeeded() async {
    final request = _controller.pendingCredentialPrompt;
    if (!mounted || request == null || _isCredentialDialogOpen) {
      return;
    }

    _controller.clearPendingCredentialPrompt();
    _isCredentialDialogOpen = true;

    final result = await showDialog<ApiCredentials>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return _ApiCredentialsDialog(
          request: request,
          initialCredentials: _controller.credentials,
        );
      },
    );

    _isCredentialDialogOpen = false;

    if (!mounted || result == null) {
      return;
    }

    await _controller.saveCredentials(result);
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyV, control: true):
            _handlePasteShortcut,
        const SingleActivator(LogicalKeyboardKey.keyV, meta: true):
            _handlePasteShortcut,
      },
      child: Focus(
        autofocus: true,
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            if (_controller.pendingCredentialPrompt != null &&
                !_isCredentialDialogOpen) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                unawaited(_presentCredentialDialogIfNeeded());
              });
            }

            return Scaffold(
              body: DecoratedBox(
                decoration: BoxDecoration(
                  color: _kBackgroundColor,
                  border: Border.all(color: _kShellBorderColor, width: 2),
                ),
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isDesktop = constraints.maxWidth >= 1360;
                      final isTablet = constraints.maxWidth >= 980;

                      if (isDesktop) {
                        return Column(
                          children: [
                            _StudioTopBar(
                              controller: _controller,
                              onConfigureKeys:
                                  _controller.requestCredentialSetup,
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: 380,
                                    child: _StudioSidebar(
                                      controller: _controller,
                                    ),
                                  ),
                                  Expanded(
                                    child: _StudioCenterStage(
                                      controller: _controller,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 430,
                                    child: _StudioInspector(
                                      controller: _controller,
                                      showProjectSummary: false,
                                      onPaste: _handlePasteShortcut,
                                      onUploadSource:
                                          _controller.pickInputImage,
                                      onUploadStyle:
                                          _controller.pickStyleReferenceImage,
                                      onConfigureKeys:
                                          _controller.requestCredentialSetup,
                                      onOptimizePrompt:
                                          _controller.optimizePromptOnly,
                                      onRender:
                                          _controller.generateArchitecture,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      if (isTablet) {
                        return Column(
                          children: [
                            _StudioTopBar(
                              controller: _controller,
                              onConfigureKeys:
                                  _controller.requestCredentialSetup,
                            ),
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: _StudioCenterStage(
                                      controller: _controller,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 392,
                                    child: _StudioInspector(
                                      controller: _controller,
                                      showProjectSummary: true,
                                      onPaste: _handlePasteShortcut,
                                      onUploadSource:
                                          _controller.pickInputImage,
                                      onUploadStyle:
                                          _controller.pickStyleReferenceImage,
                                      onConfigureKeys:
                                          _controller.requestCredentialSetup,
                                      onOptimizePrompt:
                                          _controller.optimizePromptOnly,
                                      onRender:
                                          _controller.generateArchitecture,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          _StudioTopBar(
                            controller: _controller,
                            onConfigureKeys: _controller.requestCredentialSetup,
                          ),
                          Expanded(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _CompactProjectCard(controller: _controller),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 440,
                                    child: _StudioCenterStage(
                                      controller: _controller,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _StudioInspector(
                                    controller: _controller,
                                    showProjectSummary: false,
                                    embedded: true,
                                    onPaste: _handlePasteShortcut,
                                    onUploadSource: _controller.pickInputImage,
                                    onUploadStyle:
                                        _controller.pickStyleReferenceImage,
                                    onConfigureKeys:
                                        _controller.requestCredentialSetup,
                                    onOptimizePrompt:
                                        _controller.optimizePromptOnly,
                                    onRender: _controller.generateArchitecture,
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 280,
                                    child: _StudioSidebar(
                                      controller: _controller,
                                      compact: true,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class ArchitectureStudioController extends ChangeNotifier {
  ArchitectureStudioController({
    required ApiService apiService,
    required ApiCredentialsStore credentialsStore,
  }) : _apiService = apiService,
       _credentialsStore = credentialsStore;

  final ApiService _apiService;
  final ApiCredentialsStore _credentialsStore;

  StudioViewState _viewState = StudioViewState.idle;
  Uint8List? _sourceImageBytes;
  String? _sourceImageName;
  Uint8List? _styleReferenceImageBytes;
  String? _styleReferenceImageName;
  Uint8List? _resultImageBytes;
  String? _resultPrompt;
  String? _statusMessage;
  String? _errorMessage;
  String _loadingMessage = ApiService.renderingMessage;
  String _customPrompt = '';
  ApiCredentials _credentials = const ApiCredentials.empty();
  CredentialPromptRequest? _pendingCredentialPrompt;
  ApiCredentialKind? _credentialIssueKind;
  String? _credentialIssueReason;
  BuildingType _buildingType = BuildingType.villa;
  ArchitectureStyle _style = ArchitectureStyle.modern;
  LightingCondition _lighting = LightingCondition.sunset;
  ContextPreset _contextPreset = ContextPreset.urbanStreet;
  CameraAnglePreset _cameraAnglePreset = CameraAnglePreset.wide;
  bool _isDisposed = false;

  StudioViewState get viewState => _viewState;
  Uint8List? get sourceImageBytes => _sourceImageBytes;
  String? get sourceImageName => _sourceImageName;
  Uint8List? get styleReferenceImageBytes => _styleReferenceImageBytes;
  String? get styleReferenceImageName => _styleReferenceImageName;
  Uint8List? get resultImageBytes => _resultImageBytes;
  String? get resultPrompt => _resultPrompt;
  String? get statusMessage => _statusMessage;
  String? get errorMessage => _errorMessage;
  String get loadingMessage => _loadingMessage;
  String get customPrompt => _customPrompt;
  ApiCredentials get credentials => _credentials;
  CredentialPromptRequest? get pendingCredentialPrompt =>
      _pendingCredentialPrompt;
  ApiCredentialKind? get credentialIssueKind => _credentialIssueKind;
  String? get credentialIssueReason => _credentialIssueReason;
  BuildingType get buildingType => _buildingType;
  ArchitectureStyle get style => _style;
  LightingCondition get lighting => _lighting;
  ContextPreset get contextPreset => _contextPreset;
  CameraAnglePreset get cameraAnglePreset => _cameraAnglePreset;

  bool get hasSourceImage => _sourceImageBytes != null;
  bool get hasStyleReferenceImage => _styleReferenceImageBytes != null;
  bool get hasGeminiCredential => _credentials.hasGeminiApiKey;
  bool get hasRenderCredential => _credentials.hasRenderApiKey;
  bool get hasConfiguredCredentials => _credentials.isComplete;
  bool get canOptimizePrompt =>
      hasSourceImage && _viewState != StudioViewState.loading;
  bool get canRender =>
      hasSourceImage &&
      hasConfiguredCredentials &&
      _viewState != StudioViewState.loading;

  String get livePrompt => ArchitectureFilters(
    buildingType: _buildingType,
    style: _style,
    lighting: _lighting,
  ).toEnglishPrompt(customPrompt: renderContextBrief);

  String get sourceTag => _sourceImageName ?? 'Clipboard / Imported Image';
  String get styleReferenceTag =>
      _styleReferenceImageName ?? 'Style Reference Image';
  String get projectTitle => 'Project Alpha';
  String get projectSubtitle => style.promptLabelEn;
  String get renderContextBrief {
    final parts = <String>[
      'Bối cảnh ${_contextPreset.labelVi.toLowerCase()}',
      'góc camera ${_cameraAnglePreset.labelVi.toLowerCase()}',
      if (_customPrompt.trim().isNotEmpty) _customPrompt.trim(),
    ];
    return parts.join('. ');
  }

  Future<void> initialize() async {
    try {
      final storedCredentials = await _credentialsStore.readCredentials();
      _credentials = storedCredentials.mergeMissing(
        _apiService.fallbackCredentials,
      );
      if (!_credentials.isComplete) {
        _statusMessage =
            'Lần đầu mở app, hãy nhập Gemini API key và Render API key để bắt đầu.';
        requestCredentialSetup();
      }
      _notifyListeners();
    } catch (error) {
      _errorMessage = 'Không thể đọc API key đã lưu: $error';
      _notifyListeners();
    }
  }

  Future<void> saveCredentials(ApiCredentials credentials) async {
    final normalized = credentials.trimmed();
    await _credentialsStore.saveCredentials(normalized);
    _credentials = normalized;
    _credentialIssueKind = null;
    _credentialIssueReason = null;
    try {
      final persisted = await _credentialsStore.readCredentials();
      final geminiPersisted =
          !normalized.hasGeminiApiKey ||
          persisted.geminiApiKey == normalized.geminiApiKey;
      final renderPersisted =
          !normalized.hasRenderApiKey ||
          persisted.renderApiKey == normalized.renderApiKey;

      if (geminiPersisted && renderPersisted) {
        _statusMessage = 'Đã lưu API keys trên thiết bị.';
        _errorMessage = null;
      } else {
        _statusMessage =
            'API keys đã được nạp cho phiên hiện tại nhưng chưa xác minh được việc lưu bền vững trên thiết bị.';
        _errorMessage =
            'Ứng dụng sẽ tiếp tục dùng key cho phiên hiện tại. Hãy thử mở lại app để kiểm tra persistence.';
      }
    } catch (error) {
      _statusMessage =
          'API keys đã được nạp cho phiên hiện tại nhưng không xác minh được việc lưu lâu dài trên thiết bị.';
      _errorMessage = 'Không thể đọc lại API keys sau khi lưu: $error';
    }
    _notifyListeners();
  }

  void requestCredentialSetup({ApiCredentialKind? focusKind, String? reason}) {
    _pendingCredentialPrompt = CredentialPromptRequest(
      focusKind: focusKind,
      reason: reason,
    );
    _notifyListeners();
  }

  void clearPendingCredentialPrompt() {
    _pendingCredentialPrompt = null;
    _notifyListeners();
  }

  void suggestCredentialRefresh({
    required ApiCredentialKind kind,
    required String reason,
  }) {
    _credentialIssueKind = kind;
    _credentialIssueReason = reason;
    _notifyListeners();
  }

  void openCredentialIssuePrompt() {
    final kind = _credentialIssueKind;
    if (kind == null) {
      requestCredentialSetup();
      return;
    }

    requestCredentialSetup(focusKind: kind, reason: _credentialIssueReason);
  }

  Future<void> pickInputImage() async {
    final picked = await _pickImageFile(
      dialogTitle: 'Chọn ảnh hiện trạng JPG hoặc PNG',
    );
    if (picked == null) {
      return;
    }

    _setSourceImage(
      bytes: picked.bytes,
      fileName: picked.name,
      statusMessage: 'Đã tải ảnh hiện trạng lên thành công.',
    );
  }

  Future<void> pickStyleReferenceImage() async {
    final picked = await _pickImageFile(
      dialogTitle: 'Chọn ảnh tham chiếu phong cách',
    );
    if (picked == null) {
      return;
    }

    _styleReferenceImageBytes = picked.bytes;
    _styleReferenceImageName = picked.name;
    _statusMessage = 'Đã tải ảnh tham chiếu phong cách.';
    _errorMessage = null;
    _notifyListeners();
  }

  Future<_PickedImageData?> _pickImageFile({
    required String dialogTitle,
  }) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: dialogTitle,
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png'],
        allowMultiple: false,
        withData: true,
      );

      final file = result == null || result.files.isEmpty
          ? null
          : result.files.single;
      final bytes = file?.bytes;
      if (file == null || bytes == null) {
        return null;
      }

      return _PickedImageData(bytes: bytes, name: file.name);
    } catch (error) {
      _errorMessage = 'Không thể tải ảnh lên: $error';
      _notifyListeners();
      return null;
    }
  }

  Future<void> pasteImageFromClipboard({ClipboardReader? reader}) async {
    try {
      final clipboard = SystemClipboard.instance;
      final activeReader = reader ?? await clipboard?.read();
      if (activeReader == null) {
        _errorMessage =
            'Clipboard image chưa khả dụng trên nền tảng này hoặc trình duyệt đã chặn quyền truy cập.';
        _notifyListeners();
        return;
      }

      final pngBytes = await _readClipboardFile(activeReader, Formats.png);
      final jpegBytes = await _readClipboardFile(activeReader, Formats.jpeg);
      final imageBytes = pngBytes ?? jpegBytes;
      final extension = pngBytes != null ? 'png' : 'jpg';

      if (imageBytes == null || imageBytes.isEmpty) {
        _errorMessage =
            'Không tìm thấy ảnh PNG/JPG trong clipboard. Hãy copy một hình ảnh rồi thử lại.';
        _notifyListeners();
        return;
      }

      _setSourceImage(
        bytes: imageBytes,
        fileName: 'clipboard-image.$extension',
        statusMessage: 'Đã dán ảnh từ clipboard.',
      );
    } catch (error) {
      _errorMessage = 'Không thể đọc ảnh từ clipboard: $error';
      _notifyListeners();
    }
  }

  void selectBuildingType(BuildingType value) {
    _buildingType = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  void selectStyle(ArchitectureStyle value) {
    _style = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  void selectLighting(LightingCondition value) {
    _lighting = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  void selectContextPreset(ContextPreset value) {
    _contextPreset = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  void selectCameraAnglePreset(CameraAnglePreset value) {
    _cameraAnglePreset = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  void updateCustomPrompt(String value) {
    _customPrompt = value;
    _invalidateOptimizedPrompt();
    _notifyListeners();
  }

  Future<void> optimizePromptOnly() async {
    final sourceImageBytes = _sourceImageBytes;
    if (sourceImageBytes == null) {
      _errorMessage =
          'Hãy tải ảnh lên hoặc dán ảnh từ clipboard trước khi test Step 1.';
      _notifyListeners();
      return;
    }

    if (!_credentials.hasGeminiApiKey) {
      requestCredentialSetup(
        focusKind: ApiCredentialKind.gemini,
        reason: 'Cần Gemini API key để test Step 1 tối ưu prompt.',
      );
      return;
    }

    _viewState = StudioViewState.loading;
    _errorMessage = null;
    _statusMessage = null;
    _loadingMessage = ApiService.analyzingMessage;
    _notifyListeners();

    try {
      final optimizedPrompt = await _apiService.optimizeArchitecturePrompt(
        sourceImageBytes: sourceImageBytes,
        sourceFileName: _sourceImageName ?? 'reference.png',
        buildingType: _buildingType,
        style: _style,
        lighting: _lighting,
        context: renderContextBrief,
        geminiApiKey: _credentials.geminiApiKey,
      );

      _resultPrompt = optimizedPrompt;
      _credentialIssueKind = null;
      _credentialIssueReason = null;
      _statusMessage =
          'Step 1 hoàn tất. Gemini đã tạo prompt tối ưu, bạn có thể kiểm tra trước khi qua Step 2.';
      _errorMessage = null;
      _viewState = _resultImageBytes == null
          ? StudioViewState.idle
          : StudioViewState.success;
      _notifyListeners();
    } catch (error) {
      _errorMessage = '$error';
      _statusMessage = null;
      _viewState = _resultImageBytes == null
          ? StudioViewState.idle
          : StudioViewState.success;
      if (error is ApiServiceException && error.credentialKind != null) {
        suggestCredentialRefresh(
          kind: error.credentialKind!,
          reason: error.userMessage,
        );
      } else {
        _notifyListeners();
      }
    }
  }

  void showStatus(String message) {
    _statusMessage = message;
    _errorMessage = null;
    _notifyListeners();
  }

  void startNewRender() {
    _sourceImageBytes = null;
    _sourceImageName = null;
    _styleReferenceImageBytes = null;
    _styleReferenceImageName = null;
    _resultImageBytes = null;
    _resultPrompt = null;
    _viewState = StudioViewState.idle;
    _statusMessage = 'Đã tạo phiên render mới.';
    _errorMessage = null;
    _notifyListeners();
  }

  Future<void> generateArchitecture() async {
    final sourceImageBytes = _sourceImageBytes;
    if (sourceImageBytes == null) {
      _errorMessage =
          'Hãy tải ảnh lên hoặc dán ảnh từ clipboard trước khi render.';
      _notifyListeners();
      return;
    }

    if (!_credentials.isComplete) {
      requestCredentialSetup(
        reason: 'App cần 2 API key trước khi bắt đầu render.',
      );
      return;
    }

    final cachedPrompt = _resultPrompt?.trim();
    _viewState = StudioViewState.loading;
    _errorMessage = null;
    _statusMessage = null;
    _loadingMessage = cachedPrompt == null || cachedPrompt.isEmpty
        ? ApiService.analyzingMessage
        : ApiService.renderingMessage;
    _notifyListeners();

    try {
      final result = cachedPrompt == null || cachedPrompt.isEmpty
          ? await _apiService.generateArchitecture(
              sourceImageBytes: sourceImageBytes,
              sourceFileName: _sourceImageName ?? 'reference.png',
              buildingType: _buildingType,
              style: _style,
              lighting: _lighting,
              context: renderContextBrief,
              credentials: _credentials,
              onStatusChanged: (message) {
                _loadingMessage = message;
                _notifyListeners();
              },
            )
          : await _apiService.generateArchitectureImage(
              imageBytes: sourceImageBytes,
              sourceFileName: _sourceImageName ?? 'reference.png',
              optimizedPrompt: cachedPrompt,
              renderApiKey: _credentials.renderApiKey,
            );

      _resultImageBytes = result.imageBytes;
      _resultPrompt = result.prompt;
      _credentialIssueKind = null;
      _credentialIssueReason = null;
      _statusMessage = 'Render thành công. Ảnh phối cảnh đã sẵn sàng.';
      _errorMessage = null;
      _viewState = StudioViewState.success;
      _notifyListeners();
    } catch (error) {
      _errorMessage = '$error';
      _statusMessage = null;
      _viewState = _resultImageBytes == null
          ? StudioViewState.idle
          : StudioViewState.success;
      if (error is ApiServiceException && error.credentialKind != null) {
        suggestCredentialRefresh(
          kind: error.credentialKind!,
          reason: error.userMessage,
        );
      } else {
        _notifyListeners();
      }
    }
  }

  Future<void> saveResultImage() async {
    final resultImageBytes = _resultImageBytes;
    if (resultImageBytes == null) {
      return;
    }

    final fileName = _buildResultFileName();

    try {
      String? savedPath;

      if (!kIsWeb) {
        try {
          savedPath = await FileSaver.instance.saveAs(
            name: fileName,
            bytes: resultImageBytes,
            fileExtension: 'png',
            mimeType: MimeType.png,
          );
        } catch (_) {
          savedPath = null;
        }
      }

      final effectivePath =
          savedPath ??
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: resultImageBytes,
            fileExtension: 'png',
            mimeType: MimeType.png,
          );

      _statusMessage = effectivePath.isEmpty
          ? 'Đã lưu ảnh kết quả.'
          : 'Đã lưu ảnh kết quả tại: $effectivePath';
      _errorMessage = null;
      _notifyListeners();
    } catch (error) {
      _errorMessage = 'Không thể lưu ảnh kết quả: $error';
      _notifyListeners();
    }
  }

  void clearMessages() {
    _statusMessage = null;
    _errorMessage = null;
    _credentialIssueKind = null;
    _credentialIssueReason = null;
    _notifyListeners();
  }

  void _setSourceImage({
    required Uint8List bytes,
    required String fileName,
    required String statusMessage,
  }) {
    _sourceImageBytes = bytes;
    _sourceImageName = fileName;
    _resultImageBytes = null;
    _resultPrompt = null;
    _viewState = StudioViewState.idle;
    _statusMessage = statusMessage;
    _errorMessage = null;
    _notifyListeners();
  }

  void _invalidateOptimizedPrompt() {
    _resultPrompt = null;
  }

  String _buildResultFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .replaceAll('.', '-');
    return 'archivision-render-$timestamp';
  }

  void _notifyListeners() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _apiService.dispose();
    super.dispose();
  }
}

class _PickedImageData {
  const _PickedImageData({required this.bytes, required this.name});

  final Uint8List bytes;
  final String name;
}

class _StudioTopBar extends StatelessWidget {
  const _StudioTopBar({
    required this.controller,
    required this.onConfigureKeys,
  });

  final ArchitectureStudioController controller;
  final VoidCallback onConfigureKeys;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        border: Border(bottom: BorderSide(color: _kOutlineSoftColor)),
      ),
      child: Row(
        children: [
          Text(
            'ArchiVision Studio',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          _TopBarIconButton(
            tooltip: 'Lịch sử render',
            icon: Icons.history_rounded,
            onPressed: () {
              controller.showStatus(
                'Lịch sử render sẽ được bổ sung trong bản cập nhật tiếp theo.',
              );
            },
          ),
          const SizedBox(width: 10),
          _TopBarIconButton(
            tooltip: controller.hasConfiguredCredentials
                ? 'Cập nhật API keys'
                : 'Thiết lập API keys',
            icon: Icons.settings_outlined,
            highlighted: !controller.hasConfiguredCredentials,
            onPressed: onConfigureKeys,
          ),
          const SizedBox(width: 14),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kOutlineSoftColor),
              gradient: const LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF101820)],
              ),
            ),
            child: const Center(
              child: Text('AV', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.highlighted = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: highlighted
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted ? Colors.white : Colors.transparent,
            ),
          ),
          child: Icon(icon, color: Colors.white70),
        ),
      ),
    );
  }
}

class _StudioSidebar extends StatelessWidget {
  const _StudioSidebar({required this.controller, this.compact = false});

  final ArchitectureStudioController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _kPanelColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kOutlineSoftColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.projectTitle,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        controller.projectSubtitle,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: controller.startNewRender,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New Render'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _CompactNavChip(icon: Icons.folder_outlined, label: 'Projects'),
                _CompactNavChip(icon: Icons.category_outlined, label: 'Assets'),
                _CompactNavChip(
                  icon: Icons.auto_awesome_outlined,
                  label: 'Styles',
                  selected: true,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: _kOutlineSoftColor),
            const SizedBox(height: 14),
            const Text(
              'Exterior Style  •  Interior Style  •  Landscape Style',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    final body = Container(
      color: _kPanelColor,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(28, 34, 28, 24),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: _kOutlineSoftColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.projectTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  controller.projectSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                children: [
                  _SidebarNavTile(
                    icon: Icons.folder_outlined,
                    label: 'Projects',
                  ),
                  _SidebarNavTile(
                    icon: Icons.category_outlined,
                    label: 'Assets',
                  ),
                  const SizedBox(height: 10),
                  _SidebarNavTile(
                    icon: Icons.auto_awesome_outlined,
                    label: 'Styles',
                    selected: true,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 28, top: 6),
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: _kOutlineSoftColor),
                        ),
                      ),
                      child: const Column(
                        children: [
                          _SidebarSubTile(
                            icon: Icons.home_work_outlined,
                            label: 'Exterior Style',
                          ),
                          _SidebarSubTile(
                            icon: Icons.chair_alt_outlined,
                            label: 'Interior Style',
                          ),
                          _SidebarSubTile(
                            icon: Icons.park_outlined,
                            label: 'Landscape Style',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: controller.startNewRender,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('New Render'),
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: _kOutlineSoftColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (!compact) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: _kOutlineSoftColor)),
        ),
        child: body,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: _kOutlineSoftColor),
        ),
        child: body,
      ),
    );
  }
}

class _CompactNavChip extends StatelessWidget {
  const _CompactNavChip({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.08) : _kSurfaceColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? Colors.white.withValues(alpha: 0.16)
              : _kOutlineColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.white.withValues(alpha: 0.07) : null,
        borderRadius: BorderRadius.circular(18),
        border: selected
            ? Border.all(color: Colors.white.withValues(alpha: 0.12))
            : null,
      ),
      child: ListTile(
        dense: true,
        leading: Icon(icon, color: Colors.white70),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : Colors.white70,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SidebarSubTile extends StatelessWidget {
  const _SidebarSubTile({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        leading: Icon(icon, size: 18, color: Colors.white60),
        title: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _CompactProjectCard extends StatelessWidget {
  const _CompactProjectCard({required this.controller});

  final ArchitectureStudioController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kPanelColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kOutlineSoftColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.projectTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  controller.projectSubtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: controller.startNewRender,
            icon: const Icon(Icons.add_rounded),
            label: const Text('New Render'),
          ),
        ],
      ),
    );
  }
}

class _StudioCenterStage extends StatelessWidget {
  const _StudioCenterStage({required this.controller});

  final ArchitectureStudioController controller;

  @override
  Widget build(BuildContext context) {
    final activeImageBytes = controller.viewState == StudioViewState.success
        ? controller.resultImageBytes
        : controller.sourceImageBytes ?? controller.resultImageBytes;

    return Container(
      color: _kBackgroundColor,
      child: Stack(
        children: [
          Positioned.fill(
            child: _CanvasBackdropPattern(imageBytes: activeImageBytes),
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withValues(alpha: 0.24)),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _RenderViewport(controller: controller),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasBackdropPattern extends StatelessWidget {
  const _CanvasBackdropPattern({required this.imageBytes});

  final Uint8List? imageBytes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showSideColumns = constraints.maxWidth >= 860;
        return IgnorePointer(
          child: Opacity(
            opacity: 0.34,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 1.8, sigmaY: 1.8),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 18,
                ),
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 44),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showSideColumns)
                          const Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: _GhostSettingsPanel(),
                          ),
                        Flexible(
                          flex: 8,
                          child: _BackdropImagePanel(
                            imageBytes: imageBytes,
                            alignmentSeed: index,
                          ),
                        ),
                        if (showSideColumns)
                          const Padding(
                            padding: EdgeInsets.only(left: 14),
                            child: _GhostSettingsPanel(),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GhostSettingsPanel extends StatelessWidget {
  const _GhostSettingsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 136,
      height: 306,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kOutlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 86,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44 + (index.isEven ? 18 : 0),
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.35 + (index % 3) * 0.18,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFBB7845),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BackdropImagePanel extends StatelessWidget {
  const _BackdropImagePanel({
    required this.imageBytes,
    required this.alignmentSeed,
  });

  final Uint8List? imageBytes;
  final int alignmentSeed;

  @override
  Widget build(BuildContext context) {
    final imageProvider = imageBytes == null ? null : MemoryImage(imageBytes!);

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _kOutlineColor),
        color: Colors.black,
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: imageProvider == null
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF26313F),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.architecture_rounded,
                      color: Colors.white38,
                      size: 52,
                    ),
                  ),
                )
              : Image(
                  image: imageProvider,
                  fit: BoxFit.cover,
                  alignment: switch (alignmentSeed % 3) {
                    0 => Alignment.center,
                    1 => Alignment.topCenter,
                    _ => Alignment.bottomCenter,
                  },
                ),
        ),
      ),
    );
  }
}

class _RenderViewport extends StatelessWidget {
  const _RenderViewport({required this.controller});

  final ArchitectureStudioController controller;

  @override
  Widget build(BuildContext context) {
    final displayBytes = controller.viewState == StudioViewState.success
        ? controller.resultImageBytes
        : controller.sourceImageBytes ?? controller.resultImageBytes;
    final imageProvider = displayBytes == null
        ? null
        : MemoryImage(displayBytes);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageProvider == null
                          ? const _EmptyStageSurface()
                          : InteractiveViewer(
                              minScale: 0.8,
                              maxScale: 4.0,
                              child: Image(
                                image: imageProvider,
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 18,
                      left: 18,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _StagePill(
                            icon:
                                controller.viewState == StudioViewState.success
                                ? Icons.image_search_rounded
                                : Icons.photo_outlined,
                            label:
                                controller.viewState == StudioViewState.success
                                ? 'FINAL RENDER'
                                : 'REFERENCE',
                          ),
                          _StagePill(
                            icon: Icons.auto_awesome_outlined,
                            label: controller.style.promptLabelEn.toUpperCase(),
                          ),
                        ],
                      ),
                    ),
                    if (controller.viewState == StudioViewState.success)
                      Positioned(
                        top: 18,
                        right: 18,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: controller.saveResultImage,
                              icon: const Icon(Icons.download_rounded),
                              label: const Text('Lưu ảnh kết quả'),
                            ),
                            OutlinedButton.icon(
                              onPressed: controller.generateArchitecture,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Render lại'),
                            ),
                          ],
                        ),
                      ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.48),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _MiniInfoChip(
                                      label: controller.buildingType.labelVi,
                                    ),
                                    _MiniInfoChip(
                                      label: controller.contextPreset.labelVi,
                                    ),
                                    _MiniInfoChip(
                                      label:
                                          controller.cameraAnglePreset.labelVi,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  controller.resultPrompt ??
                                      controller.livePrompt,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (controller.viewState == StudioViewState.loading)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.58),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(strokeWidth: 3),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            controller.loadingMessage,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStageSurface extends StatelessWidget {
  const _EmptyStageSurface();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF171A1F),
            Colors.black.withValues(alpha: 0.94),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: const Icon(
                  Icons.image_outlined,
                  color: Colors.white70,
                  size: 38,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Canvas đang chờ ảnh tham chiếu',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Tải ảnh lên hoặc dán ảnh từ clipboard để AI bắt đầu phân tích bố cục và tạo phối cảnh.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StagePill extends StatelessWidget {
  const _StagePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StudioInspector extends StatelessWidget {
  const _StudioInspector({
    required this.controller,
    required this.showProjectSummary,
    this.embedded = false,
    required this.onPaste,
    required this.onUploadSource,
    required this.onUploadStyle,
    required this.onConfigureKeys,
    required this.onOptimizePrompt,
    required this.onRender,
  });

  final ArchitectureStudioController controller;
  final bool showProjectSummary;
  final bool embedded;
  final Future<void> Function() onPaste;
  final Future<void> Function() onUploadSource;
  final Future<void> Function() onUploadStyle;
  final VoidCallback onConfigureKeys;
  final Future<void> Function() onOptimizePrompt;
  final Future<void> Function() onRender;

  @override
  Widget build(BuildContext context) {
    final isLoading = controller.viewState == StudioViewState.loading;
    final bodyContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showProjectSummary) ...[
          _CompactProjectCard(controller: controller),
          const SizedBox(height: 22),
        ],
        _InspectorBadges(controller: controller),
        const SizedBox(height: 22),
        const _SectionLabel('DỮ LIỆU HÌNH ẢNH'),
        const SizedBox(height: 14),
        _UploadSlotCard(
          title: '1. ẢNH HIỆN TRẠNG / BỐ CỤC',
          icon: Icons.image_outlined,
          buttonLabel: 'Tải ảnh lên',
          helperText: 'Dán ảnh Ctrl+V / Cmd+V hoặc import JPG/PNG.',
          imageBytes: controller.sourceImageBytes,
          fileName: controller.sourceTag,
          onPressed: isLoading ? null : onUploadSource,
          onSecondaryPressed: isLoading ? null : onPaste,
          secondaryLabel: 'Dán clipboard',
        ),
        const SizedBox(height: 14),
        _UploadSlotCard(
          title: '2. ẢNH THAM CHIẾU (STYLE)',
          icon: Icons.palette_outlined,
          buttonLabel: 'Tải ảnh mẫu',
          helperText: 'Ảnh mẫu giúp AI bám vật liệu, mood và ngôn ngữ thẩm mỹ.',
          imageBytes: controller.styleReferenceImageBytes,
          fileName: controller.styleReferenceTag,
          onPressed: isLoading ? null : onUploadStyle,
        ),
        const SizedBox(height: 26),
        const _SectionLabel('PROMPT (CÂU LỆNH)'),
        const SizedBox(height: 14),
        TextFormField(
          key: const ValueKey('customPromptField'),
          initialValue: controller.customPrompt,
          onChanged: controller.updateCustomPrompt,
          minLines: 5,
          maxLines: 7,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'ảnh chụp thực tế',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: controller.canOptimizePrompt && !isLoading
                ? () => unawaited(onOptimizePrompt())
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: _kAccentColor,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.auto_fix_high_rounded),
            label: const Text('AI Tối ưu Prompt'),
          ),
        ),
        if (controller.resultPrompt != null) ...[
          const SizedBox(height: 16),
          const _SectionLabel('PROMPT GEMINI (STEP 1)'),
          const SizedBox(height: 10),
          _ReadOnlyPromptCard(prompt: controller.resultPrompt!),
        ],
        const SizedBox(height: 26),
        const _SectionLabel('BỘ LỌC NHANH'),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.38,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _DropdownField<BuildingType>(
              label: 'CÔNG TRÌNH',
              value: controller.buildingType,
              items: BuildingType.values,
              itemLabelBuilder: (item) => item.labelVi,
              onChanged: isLoading ? null : controller.selectBuildingType,
            ),
            _DropdownField<ArchitectureStyle>(
              label: 'STYLE',
              value: controller.style,
              items: ArchitectureStyle.values,
              itemLabelBuilder: (item) => item.labelVi,
              onChanged: isLoading ? null : controller.selectStyle,
            ),
            _DropdownField<ContextPreset>(
              label: 'BỐI CẢNH',
              value: controller.contextPreset,
              items: ContextPreset.values,
              itemLabelBuilder: (item) => item.labelVi,
              onChanged: isLoading ? null : controller.selectContextPreset,
            ),
            _DropdownField<LightingCondition>(
              label: 'ÁNH SÁNG',
              value: controller.lighting,
              items: LightingCondition.values,
              itemLabelBuilder: (item) => item.labelVi,
              onChanged: isLoading ? null : controller.selectLighting,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _DropdownField<CameraAnglePreset>(
          label: 'GÓC CAMERA',
          value: controller.cameraAnglePreset,
          items: CameraAnglePreset.values,
          itemLabelBuilder: (item) => item.labelVi,
          onChanged: isLoading ? null : controller.selectCameraAnglePreset,
        ),
        const SizedBox(height: 18),
        _InspectorStatusCard(
          controller: controller,
          onConfigureKeys: onConfigureKeys,
        ),
      ],
    );
    final scrollBody = SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: bodyContent,
    );

    return Container(
      decoration: const BoxDecoration(
        color: _kPanelColor,
        border: Border(left: BorderSide(color: _kOutlineSoftColor)),
      ),
      child: Column(
        mainAxisSize: embedded ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (embedded)
            Padding(padding: const EdgeInsets.all(28), child: bodyContent)
          else
            Expanded(child: Scrollbar(child: scrollBody)),
          Container(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 28),
            decoration: const BoxDecoration(
              color: _kPanelColor,
              border: Border(top: BorderSide(color: _kOutlineSoftColor)),
            ),
            child: Column(
              children: [
                if (controller.viewState == StudioViewState.success) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.saveResultImage,
                          icon: const Icon(Icons.download_rounded),
                          label: const Text('Lưu ảnh kết quả'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: controller.generateArchitecture,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Render lại'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: controller.canRender ? onRender : null,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.bolt_rounded),
                    label: Text(
                      isLoading ? 'ĐANG RENDER...' : 'BẮT ĐẦU RENDER',
                    ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(68),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorBadges extends StatelessWidget {
  const _InspectorBadges({required this.controller});

  final ArchitectureStudioController controller;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoBadge(
          icon: controller.hasGeminiCredential
              ? Icons.key_rounded
              : Icons.key_off_rounded,
          label: controller.hasGeminiCredential
              ? 'Gemini Ready'
              : 'Missing Gemini Key',
          color: controller.hasGeminiCredential
              ? _kSuccessColor
              : Theme.of(context).colorScheme.error,
        ),
        _InfoBadge(
          icon: controller.hasRenderCredential
              ? Icons.bolt_rounded
              : Icons.bolt_outlined,
          label: controller.hasRenderCredential
              ? 'Render Ready'
              : 'Missing Render Key',
          color: controller.hasRenderCredential
              ? _kSuccessColor
              : Colors.white70,
        ),
        const _InfoBadge(
          icon: Icons.content_paste_rounded,
          label: 'Clipboard Ready',
          color: Colors.white70,
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  const _InfoBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyPromptCard extends StatelessWidget {
  const _ReadOnlyPromptCard({required this.prompt});

  final String prompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SelectionArea(
        child: Text(
          prompt,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.6),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: Colors.white70),
    );
  }
}

class _UploadSlotCard extends StatelessWidget {
  const _UploadSlotCard({
    required this.title,
    required this.icon,
    required this.buttonLabel,
    required this.helperText,
    required this.imageBytes,
    required this.fileName,
    required this.onPressed,
    this.onSecondaryPressed,
    this.secondaryLabel,
  });

  final String title;
  final IconData icon;
  final String buttonLabel;
  final String helperText;
  final Uint8List? imageBytes;
  final String fileName;
  final Future<void> Function()? onPressed;
  final Future<void> Function()? onSecondaryPressed;
  final String? secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final imageProvider = imageBytes == null ? null : MemoryImage(imageBytes!);

    return _DashedBorderContainer(
      child: Container(
        decoration: BoxDecoration(
          color: _kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              height: 142,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
              ),
              child: imageProvider == null
                  ? Center(child: Icon(icon, size: 38, color: Colors.white54))
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image(image: imageProvider, fit: BoxFit.cover),
                          Positioned(
                            left: 10,
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.54),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                fileName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onPressed == null
                    ? null
                    : () => unawaited(onPressed!()),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  side: const BorderSide(color: _kOutlineColor),
                ),
                child: Text(buttonLabel),
              ),
            ),
            if (secondaryLabel != null && onSecondaryPressed != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => unawaited(onSecondaryPressed!()),
                  child: Text(secondaryLabel!),
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              helperText,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _kMutedTextColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabelBuilder,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kSurfaceColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kOutlineColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _kMutedTextColor,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 2),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: _kPanelColorDeep,
              borderRadius: BorderRadius.circular(16),
              icon: const Icon(
                Icons.expand_more_rounded,
                color: Colors.white54,
              ),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem<T>(
                      value: item,
                      child: Text(
                        itemLabelBuilder(item),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: onChanged == null
                  ? null
                  : (value) {
                      if (value != null) {
                        onChanged!(value);
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }
}

class _InspectorStatusCard extends StatelessWidget {
  const _InspectorStatusCard({
    required this.controller,
    required this.onConfigureKeys,
  });

  final ArchitectureStudioController controller;
  final VoidCallback onConfigureKeys;

  @override
  Widget build(BuildContext context) {
    final loadingMessage = controller.viewState == StudioViewState.loading
        ? controller.loadingMessage
        : null;
    final hasCredentialIssue = controller.credentialIssueKind != null;
    final hasMessage =
        loadingMessage != null ||
        controller.statusMessage != null ||
        controller.errorMessage != null ||
        hasCredentialIssue ||
        !controller.hasConfiguredCredentials;

    if (!hasMessage) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!controller.hasConfiguredCredentials) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  controller.hasGeminiCredential
                      ? Icons.info_outline_rounded
                      : Icons.key_off_rounded,
                  color: controller.hasGeminiCredential
                      ? Colors.white70
                      : Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    switch ((
                      controller.hasGeminiCredential,
                      controller.hasRenderCredential,
                    )) {
                      (true, false) =>
                        'Step 1 đã sẵn sàng. Thêm Render API key khi bạn muốn chạy Step 2 để gen ảnh.',
                      (false, true) =>
                        'Thiếu Gemini API key nên chưa thể test Step 1 tối ưu prompt.',
                      _ =>
                        'Bạn có thể nhập Gemini API key trước để test Step 1, sau đó thêm Render API key cho Step 2.',
                    },
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: onConfigureKeys,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Nhập API Keys'),
            ),
          ],
          if (hasCredentialIssue) ...[
            if (controller.hasConfiguredCredentials) const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: controller.openCredentialIssuePrompt,
              icon: Icon(
                controller.credentialIssueKind == ApiCredentialKind.gemini
                    ? Icons.key_rounded
                    : Icons.bolt_rounded,
              ),
              label: Text(
                controller.credentialIssueKind == ApiCredentialKind.gemini
                    ? 'Nhập lại Gemini key'
                    : 'Nhập lại Render key',
              ),
            ),
          ],
          if (loadingMessage != null) ...[
            const SizedBox(height: 10),
            _StatusLine(
              icon: Icons.hourglass_top_rounded,
              color: Colors.white,
              text: loadingMessage,
            ),
          ],
          if (controller.statusMessage != null) ...[
            const SizedBox(height: 10),
            _StatusLine(
              icon: Icons.check_circle_rounded,
              color: _kSuccessColor,
              text: controller.statusMessage!,
            ),
          ],
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 10),
            _StatusLine(
              icon: Icons.error_rounded,
              color: Theme.of(context).colorScheme.error,
              text: controller.errorMessage!,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _DashedBorderContainer extends StatelessWidget {
  const _DashedBorderContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _DashedBorderPainter(), child: child);
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(20);
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect.deflate(0.5), radius);
    final path = Path()..addRRect(rrect);

    final paint = Paint()
      ..color = _kDashedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final nextDistance = distance + 6;
        canvas.drawPath(metric.extractPath(distance, nextDistance), paint);
        distance += 10;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CredentialPromptRequest {
  const CredentialPromptRequest({this.focusKind, this.reason});

  final ApiCredentialKind? focusKind;
  final String? reason;
}

class _ApiCredentialsDialog extends StatefulWidget {
  const _ApiCredentialsDialog({
    required this.request,
    required this.initialCredentials,
  });

  final CredentialPromptRequest request;
  final ApiCredentials initialCredentials;

  @override
  State<_ApiCredentialsDialog> createState() => _ApiCredentialsDialogState();
}

class _ApiCredentialsDialogState extends State<_ApiCredentialsDialog> {
  late final TextEditingController _geminiController;
  late final TextEditingController _renderController;
  bool _obscureGemini = true;
  bool _obscureRender = true;

  @override
  void initState() {
    super.initState();
    _geminiController = TextEditingController(
      text: widget.initialCredentials.geminiApiKey,
    );
    _renderController = TextEditingController(
      text: widget.initialCredentials.renderApiKey,
    );
  }

  @override
  void dispose() {
    _geminiController.dispose();
    _renderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focusKind = widget.request.focusKind;
    final headline = switch (focusKind) {
      ApiCredentialKind.gemini => 'Cập nhật Gemini API key',
      ApiCredentialKind.render => 'Cập nhật Render API key',
      null => 'Thiết lập API keys',
    };
    final reason =
        widget.request.reason ??
        'App sẽ lưu 2 key này trên thiết bị để những lần mở sau không cần nhập lại.';

    return AlertDialog(
      backgroundColor: _kPanelColorDeep,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(headline),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reason,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: _geminiController,
                autofocus:
                    focusKind == null || focusKind == ApiCredentialKind.gemini,
                obscureText: _obscureGemini,
                decoration: InputDecoration(
                  labelText: 'Gemini API key',
                  hintText: 'Nhập key dùng cho bước phân tích ảnh',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureGemini = !_obscureGemini;
                      });
                    },
                    icon: Icon(
                      _obscureGemini
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _renderController,
                autofocus: focusKind == ApiCredentialKind.render,
                obscureText: _obscureRender,
                decoration: InputDecoration(
                  labelText: 'Render API key',
                  hintText: 'Nhập key dùng cho bước render ảnh',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscureRender = !_obscureRender;
                      });
                    },
                    icon: Icon(
                      _obscureRender
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Để sau'),
        ),
        FilledButton(
          onPressed: () {
            final credentials = ApiCredentials(
              geminiApiKey: _geminiController.text,
              renderApiKey: _renderController.text,
            ).trimmed();

            if (!credentials.hasGeminiApiKey && !credentials.hasRenderApiKey) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hãy nhập ít nhất 1 API key để lưu.'),
                ),
              );
              return;
            }

            Navigator.of(context).pop(credentials);
          },
          child: const Text('Lưu API Keys'),
        ),
      ],
    );
  }
}

Future<Uint8List?> _readClipboardFile(
  ClipboardReader reader,
  FileFormat format,
) {
  final completer = Completer<Uint8List?>();
  final progress = reader.getFile(format, (file) async {
    try {
      completer.complete(await file.readAll());
    } catch (error) {
      completer.completeError(error);
    }
  }, onError: completer.completeError);

  if (progress == null) {
    completer.complete(null);
  }

  return completer.future;
}
