import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:recipes/ui/widgets/ingredient_card.dart';

void main() {
  const mockIngredientName = 'colby jack cheese';

  // This singleton service executes the integration test on a real device.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('can build', (tester) async {
      // Arrange
      // pumpWidget() to render the Ul for your widget.
      await tester.pumpWidget(
        buildWrappedIntegrationTestWidget(IngredientCard(
          name: mockIngredientName,
          initiallyChecked: false,
          evenRow: true,
          onChecked: (isChecked) {},
        )),
      );

      // Act
      // find.byType() allows me to find a widget by its type.
      final cardFinder = find.byType(IngredientCard);
      final titleFinder = find.text(mockIngredientName);

      // Assert
      expect(cardFinder, findsOneWidget);
      expect(titleFinder, findsOneWidget);
    });
  });
}

Widget buildWrappedIntegrationTestWidget(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: ListView(
        children: [
          child,
        ],
      ),
    ),
  );
}
