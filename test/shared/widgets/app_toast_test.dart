import 'package:flinx/shared/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';

void main() {
  testWidgets('server error takes priority over generic error toasts', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    AppToast.reserveServerError();
    AppToast.error(context, 'Network unavailable.');
    await tester.pump();
    expect(find.text('Network unavailable.'), findsNothing);

    AppToast.serverError(context, 'Account already exists.');
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Account already exists.'), findsOneWidget);

    AppToast.error(context, 'Please try again.');
    await tester.pump();
    expect(find.text('Please try again.'), findsNothing);
    expect(find.text('Account already exists.'), findsOneWidget);

    toastification.dismissAll(delayForAnimation: false);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();
  });
}
