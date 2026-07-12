import 'package:eduself_study_app/shared/widgets/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ChatBubble renders markdown bold and list markers',
      (tester) async {
    const markdown = '''
**Định lý Pitago**

* Hình học không gian
* Hình Oxyz

\$\$a^2 + b^2 = c^2\$\$
''';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ChatBubble(
              text: markdown,
              isUser: false,
            ),
          ),
        ),
      ),
    );

    expect(find.textContaining('Định lý Pitago'), findsOneWidget);
    expect(find.textContaining('Hình học không gian'), findsOneWidget);
    // Raw markdown markers should not appear as plain asterisks for bold title.
    expect(find.text('**Định lý Pitago**'), findsNothing);
  });
}
