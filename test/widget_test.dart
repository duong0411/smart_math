import 'package:eduself_study_app/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app boots to math home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: EduSelfApp()));
    await tester.pumpAndSettle();
    expect(find.textContaining('EduSelf'), findsWidgets);
    expect(find.textContaining('Địa lí'), findsWidgets);
  });
}
