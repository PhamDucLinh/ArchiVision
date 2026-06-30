import 'package:flutter_test/flutter_test.dart';

import 'package:archi_vision/main.dart';

void main() {
  testWidgets('ArchiVision converter screen renders', (tester) async {
    await tester.pumpWidget(const ArchiVisionApp());

    expect(find.text('ArchiVision'), findsOneWidget);
    expect(find.text('Chọn file .dwg/.skp/.skb'), findsOneWidget);
    expect(find.text('Convert'), findsOneWidget);
    expect(find.text('Ảnh PNG sẽ hiển thị tại đây'), findsOneWidget);
  });
}
