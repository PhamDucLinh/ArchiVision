import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const ArchiVisionApp());
}

class ArchiVisionApp extends StatelessWidget {
  const ArchiVisionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ArchiVision',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF256B63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
      ),
      home: const ConverterScreen(),
    );
  }
}

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  String? _selectedInputPath;
  String? _outputPngPath;
  String? _message;
  String? _error;
  bool _isConverting = false;

  Future<void> _pickInputFile() async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: 'Chọn file DWG, SKP hoặc SKB',
        type: FileType.custom,
        allowedExtensions: const ['dwg', 'skp', 'skb'],
        allowMultiple: false,
      );

      final path = result?.files.single.path;
      if (path == null) {
        return;
      }

      setState(() {
        _selectedInputPath = path;
        _outputPngPath = _buildOutputPath(path);
        _message = 'Đã chọn file ${_extensionOf(path).toUpperCase()}.';
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = 'Không thể chọn file: $e';
        _message = null;
      });
    }
  }

  Future<void> _convertSelectedFile() async {
    final inputPath = _selectedInputPath;
    final outputPath = _outputPngPath;

    if (inputPath == null || outputPath == null) {
      setState(() {
        _error =
            'Vui lòng chọn một file .dwg, .skp hoặc .skb trước khi convert.';
        _message = null;
      });
      return;
    }

    final extension = _extensionOf(inputPath);
    setState(() {
      _isConverting = true;
      _error = null;
      _message = 'Đang chuyển đổi ${extension.toUpperCase()} sang PNG...';
    });

    try {
      final pythonCommand = _pythonCommand();
      final result = await _runBackend(
        pythonCommand: pythonCommand,
        inputPath: inputPath,
        outputPath: outputPath,
        extension: extension,
      );

      if (!mounted) {
        return;
      }

      if (result.exitCode == 0 && File(outputPath).existsSync()) {
        setState(() {
          _isConverting = false;
          _outputPngPath = outputPath;
          _message = 'Convert thành công. Ảnh PNG đã được tạo.';
          _error = null;
        });
      } else {
        final details = [
          if (result.stdout.toString().trim().isNotEmpty)
            result.stdout.toString().trim(),
          if (result.stderr.toString().trim().isNotEmpty)
            result.stderr.toString().trim(),
        ].join('\n');

        setState(() {
          _isConverting = false;
          _error =
              'Convert thất bại với exitCode ${result.exitCode}.\n$details';
          _message = null;
        });
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isConverting = false;
        _error = 'Không thể chạy Python backend: $e';
        _message = null;
      });
    }
  }

  Future<ProcessResult> _runBackend({
    required _PythonCommand pythonCommand,
    required String inputPath,
    required String outputPath,
    required String extension,
  }) async {
    if (extension == 'dwg') {
      final scriptPath = await _prepareBackendScript('convert.py');
      return Process.run(pythonCommand.executable, [
        ...pythonCommand.arguments,
        scriptPath,
        inputPath,
        outputPath,
      ], runInShell: Platform.isWindows);
    }

    if (extension == 'skp' || extension == 'skb') {
      final scriptPath = await _prepareBackendScript('skp_wrapper.py');
      final processorPath = _findSkpProcessorExecutable();
      return Process.run(pythonCommand.executable, [
        ...pythonCommand.arguments,
        scriptPath,
        inputPath,
        outputPath,
        '--mode',
        'thumbnail',
        if (processorPath != null) ...['--processor', processorPath],
      ], runInShell: Platform.isWindows);
    }

    throw Exception('Định dạng chưa được hỗ trợ: .$extension');
  }

  String _buildOutputPath(String inputPath) {
    final inputFile = File(inputPath);
    final parentPath = inputFile.parent.path;
    final fileName = inputFile.uri.pathSegments.isNotEmpty
        ? inputFile.uri.pathSegments.last
        : 'drawing.dwg';
    final dotIndex = fileName.lastIndexOf('.');
    final nameWithoutExtension = dotIndex > 0
        ? fileName.substring(0, dotIndex)
        : fileName;

    return '$parentPath${Platform.pathSeparator}$nameWithoutExtension.png';
  }

  Future<String> _prepareBackendScript(String fileName) async {
    final projectScript = _findLocalBackendScript(fileName);
    if (projectScript != null) {
      return projectScript;
    }

    try {
      final scriptContent = await rootBundle.loadString(fileName);
      final scriptDir = Directory(
        '${Directory.systemTemp.path}${Platform.pathSeparator}archivision_backend',
      );
      if (!scriptDir.existsSync()) {
        scriptDir.createSync(recursive: true);
      }

      final scriptFile = File(
        '${scriptDir.path}${Platform.pathSeparator}$fileName',
      );
      scriptFile.writeAsStringSync(scriptContent, flush: true);
      return scriptFile.path;
    } catch (e) {
      throw Exception(
        'Không tìm thấy $fileName. Hãy kiểm tra pubspec.yaml đã khai báo asset $fileName. Chi tiết: $e',
      );
    }
  }

  String? _findLocalBackendScript(String fileName) {
    final separator = Platform.pathSeparator;
    final candidates = <File>[
      File('${Directory.current.path}$separator$fileName'),
      File(
        '${File(Platform.resolvedExecutable).parent.path}$separator$fileName',
      ),
      File(
        '${File(Platform.resolvedExecutable).parent.parent.path}${separator}Resources$separator$fileName',
      ),
    ];

    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }

    return null;
  }

  String? _findSkpProcessorExecutable() {
    final separator = Platform.pathSeparator;
    final executableName = Platform.isWindows
        ? 'skp_processor.exe'
        : 'skp_processor';
    final candidates = <File>[
      File(
        '${Directory.current.path}${separator}native${separator}skp_processor${separator}build$separator$executableName',
      ),
      File(
        '${Directory.current.path}${separator}native${separator}skp_processor${separator}build${separator}Release$separator$executableName',
      ),
      File(
        '${File(Platform.resolvedExecutable).parent.path}$separator$executableName',
      ),
    ];

    for (final candidate in candidates) {
      if (candidate.existsSync()) {
        return candidate.path;
      }
    }

    return null;
  }

  String _extensionOf(String path) {
    final fileName = File(path).uri.pathSegments.isNotEmpty
        ? File(path).uri.pathSegments.last
        : path;
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '';
    }
    return fileName.substring(dotIndex + 1).toLowerCase();
  }

  _PythonCommand _pythonCommand() {
    if (Platform.isWindows) {
      return const _PythonCommand('py', ['-3']);
    }

    return const _PythonCommand('python3', []);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outputPath = _outputPngPath;
    final hasImage = outputPath != null && File(outputPath).existsSync();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ArchiVision'),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Chip(
              avatar: Icon(
                Icons.desktop_windows_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: const Text('DWG / SKP / SKB'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 360,
                child: _ControlPanel(
                  selectedPath: _selectedInputPath,
                  outputPath: _outputPngPath,
                  message: _message,
                  error: _error,
                  isConverting: _isConverting,
                  onPickFile: _isConverting ? null : _pickInputFile,
                  onConvert: _isConverting ? null : _convertSelectedFile,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: _PreviewPane(
                  imagePath: hasImage ? outputPath : null,
                  isConverting: _isConverting,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlPanel extends StatelessWidget {
  const _ControlPanel({
    required this.selectedPath,
    required this.outputPath,
    required this.message,
    required this.error,
    required this.isConverting,
    required this.onPickFile,
    required this.onConvert,
  });

  final String? selectedPath;
  final String? outputPath;
  final String? message;
  final String? error;
  final bool isConverting;
  final VoidCallback? onPickFile;
  final VoidCallback? onConvert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chuyển đổi bản vẽ',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chọn file DWG, SKP hoặc SKB, sau đó hệ thống sẽ gọi backend để tạo ảnh PNG.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPickFile,
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Chọn file .dwg/.skp/.skb'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: selectedPath == null ? null : onConvert,
                icon: isConverting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(isConverting ? 'Đang xử lý...' : 'Convert'),
              ),
            ),
            const SizedBox(height: 28),
            _PathBlock(
              title: 'File đầu vào',
              path: selectedPath ?? 'Chưa chọn file',
            ),
            const SizedBox(height: 16),
            _PathBlock(
              title: 'File PNG đầu ra',
              path:
                  outputPath ?? 'Sẽ tự động tạo cùng thư mục với file đầu vào',
            ),
            const SizedBox(height: 24),
            if (message != null)
              _StatusBox(
                icon: Icons.check_circle_rounded,
                color: Colors.green.shade700,
                text: message!,
              ),
            if (error != null)
              _StatusBox(
                icon: Icons.error_rounded,
                color: theme.colorScheme.error,
                text: error!,
              ),
          ],
        ),
      ),
    );
  }
}

class _PathBlock extends StatelessWidget {
  const _PathBlock({required this.title, required this.path});

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SelectableText(
          path,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  const _StatusBox({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.28)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPane extends StatelessWidget {
  const _PreviewPane({required this.imagePath, required this.isConverting});

  final String? imagePath;
  final bool isConverting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: imagePath == null
                ? _EmptyPreview(isConverting: isConverting)
                : InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 6,
                    child: Center(
                      child: Image.file(
                        File(imagePath!),
                        key: ValueKey(imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
          ),
          Positioned(
            left: 18,
            top: 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.92),
                border: Border.all(color: theme.colorScheme.outlineVariant),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text('Preview PNG'),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.isConverting});

  final bool isConverting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isConverting)
            const CircularProgressIndicator()
          else
            Icon(
              Icons.architecture_rounded,
              size: 64,
              color: theme.colorScheme.primary,
            ),
          const SizedBox(height: 18),
          Text(
            isConverting
                ? 'Đang render bản vẽ...'
                : 'Ảnh PNG sẽ hiển thị tại đây',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PythonCommand {
  const _PythonCommand(this.executable, this.arguments);

  final String executable;
  final List<String> arguments;
}
