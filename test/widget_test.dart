import 'package:flutter_test/flutter_test.dart';
import 'package:simonipu/main.dart';

void main() {
  testWidgets('SIMONI PU App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const SimoniPuApp());
    expect(find.byType(SimoniPuApp), findsOneWidget);
  });
}
