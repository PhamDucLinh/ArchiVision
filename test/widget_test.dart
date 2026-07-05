import 'package:flutter_test/flutter_test.dart';

import 'package:archi_vision/main.dart';
import 'package:archi_vision/services/api_credentials_store.dart';

void main() {
  testWidgets('ArchiVision studio screen renders', (tester) async {
    await tester.pumpWidget(
      ArchiVisionApp(
        credentialsStore: MemoryApiCredentialsStore(
          initialCredentials: const ApiCredentials(
            geminiApiKey: 'gemini-test-key',
            renderApiKey: 'render-test-key',
          ),
        ),
      ),
    );

    expect(find.text('ArchiVision Studio'), findsOneWidget);
    expect(find.text('Project Alpha'), findsWidgets);
    expect(find.text('DỮ LIỆU HÌNH ẢNH'), findsOneWidget);
    expect(find.text('Tải ảnh lên'), findsOneWidget);
    expect(find.text('PROMPT (CÂU LỆNH)'), findsOneWidget);
    expect(find.text('AI Tối ưu Prompt'), findsOneWidget);
    expect(find.text('BẮT ĐẦU RENDER'), findsOneWidget);
  });
}
