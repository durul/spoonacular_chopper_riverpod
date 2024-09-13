import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:recipes/ui/widgets/ingredient_card.dart';

import 'widget_test_helper.dart';

void main() {
  const mockIngredientName = 'colby jack cheese';

  group('IngredientCard', () {
    testWidgets('can build', (tester) async {
      // Arrange
      // pumpWidget() to render the Ul for your widget.
      await tester.pumpWidget(
        buildWrappedWidget(IngredientCard(
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

    testWidgets('can be checked when tapped', (tester) async {
      var isChecked = false;
      await tester.pumpWidget(
        buildWrappedWidget(IngredientCard(
          name: mockIngredientName,
          initiallyChecked: isChecked,
          evenRow: true,
          onChecked: (newValue) {
            isChecked = newValue;
          },
        )),
      );

      // Act
      final cardFinder = find.byType(IngredientCard);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);

      // Assert
      expect(checkboxFinder, findsOneWidget);
      expect(isChecked, isTrue);
    });

    testWidgets('can be unchecked when tapped', (tester) async {
      var isChecked = true;
      await tester.pumpWidget(
        buildWrappedWidget(IngredientCard(
          name: mockIngredientName,
          initiallyChecked: isChecked,
          evenRow: true,
          onChecked: (newValue) {
            isChecked = newValue;
          },
        )),
      );

      // Act
      final cardFinder = find.byType(IngredientCard);

      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      final checkboxFinder = find.byType(Checkbox);

      // Assert
      expect(checkboxFinder, findsOneWidget);
      expect(isChecked, isFalse);
    });

    // Add a test to verify that the evenRow parameter is respected.
    testWidgets('can be styled differently based on evenRow parameter',
        (tester) async {
      // Arrange
      await tester.pumpWidget(
        buildWrappedWidget(IngredientCard(
          name: mockIngredientName,
          initiallyChecked: false,
          evenRow: true,
          onChecked: (isChecked) {},
        )),
      );

      // Act
      final cardFinder = find.byType(IngredientCard);
      final card = tester.widget<IngredientCard>(cardFinder);

      // Assert
      expect(card.evenRow, isTrue);
    });

    // Add a test to verify that the onChecked callback is called when the checkbox is tapped.
    testWidgets('can call onChecked callback when checkbox is tapped',
        (tester) async {
      // Arrange
      var isChecked = false;
      await tester.pumpWidget(
        buildWrappedWidget(IngredientCard(
          name: mockIngredientName,
          initiallyChecked: isChecked,
          evenRow: true,
          onChecked: (newValue) {
            isChecked = newValue;
          },
        )),
      );

      // Act
      final checkboxFinder = find.byType(Checkbox);

      await tester.tap(checkboxFinder);
      await tester.pumpAndSettle();

      // Assert
      expect(isChecked, isTrue);
    });
  });
}
