import 'package:flinx/core/errors/app_error.dart';
import 'package:flinx/core/errors/app_error_message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses a non-empty business response message', () {
    const error = AppError(
      code: AppErrorCode.serverError,
      messageKey: 'scene.createFailed',
      businessCode: 100500,
      userMessage: '  Scene name is already in use.  ',
    );

    expect(
      appErrorMessage(error, 'Unable to create the scene.'),
      'Scene name is already in use.',
    );
  });

  test('uses the localized fallback when the message is absent', () {
    const error = AppError(
      code: AppErrorCode.serverError,
      messageKey: 'scene.createFailed',
      businessCode: 100500,
      userMessage: '  ',
    );

    expect(
      appErrorMessage(error, 'Unable to create the scene.'),
      'Unable to create the scene.',
    );
    expect(
      appErrorMessage(StateError('unexpected'), 'Unable to create the scene.'),
      'Unable to create the scene.',
    );
  });
}
