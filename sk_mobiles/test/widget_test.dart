import 'package:flutter_test/flutter_test.dart';
import 'package:sk_mobiles/main.dart';

void main() {
  testWidgets('App launches', (WidgetTester tester) async {
    await tester.pumpWidget(const SKMobilesApp());
  });
}