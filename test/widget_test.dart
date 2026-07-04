import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:node_management_app/app/app.dart';

void main() {
  testWidgets('App smoke test — renders without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: NodeOpsApp()),
    );
    await tester.pump();
    // App should render without throwing
    expect(tester.takeException(), isNull);
  });
}
