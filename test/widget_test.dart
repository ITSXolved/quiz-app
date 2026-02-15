import 'package:flutter_test/flutter_test.dart';
import 'package:noor_e_quran/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const NoorEQuranApp());
    expect(find.text('Noor-e-Quran'), findsOneWidget);
  });
}
