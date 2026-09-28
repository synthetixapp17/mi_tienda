import 'package:flutter_test/flutter_test.dart';
import 'package:sinthetix_pro/main.dart';

void main() {
  testWidgets('SINTHETIX PRO inicia correctamente', (tester) async {
    await tester.pumpWidget(const MiApp());
    await tester.pump();
    expect(find.byType(MiApp), findsOneWidget);
  });
}
