import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';

void main() {
  group('EditModeController: inatividade', () {
    test('lock() manual não conta como inatividade', () {
      final controller = EditModeController()..enter();

      controller.lock();

      expect(controller.isEditing, isFalse);
      expect(controller.lastLockWasIdle, isFalse);
    });

    test('lockForInactivity() trava e marca o motivo', () {
      final controller = EditModeController()..enter();

      controller.lockForInactivity();

      expect(controller.isEditing, isFalse);
      expect(controller.lastLockWasIdle, isTrue);
    });

    test('entrar de novo limpa o motivo do último bloqueio', () {
      final controller = EditModeController()
        ..enter()
        ..lockForInactivity()
        ..enter();

      expect(controller.isEditing, isTrue);
      expect(controller.lastLockWasIdle, isFalse);
    });

    test('travar fora da edição não avisa nem muda o motivo', () {
      final controller = EditModeController();
      var calls = 0;
      controller.addListener(() => calls++);

      controller.lockForInactivity();

      expect(calls, 0);
      expect(controller.lastLockWasIdle, isFalse);
    });

    test('registerActivity só avisa durante a edição', () {
      final controller = EditModeController();
      var pings = 0;
      controller.activity.addListener(() => pings++);

      controller.registerActivity();
      expect(pings, 0);

      controller.enter();
      controller.registerActivity();
      controller.registerActivity();
      expect(pings, 2);

      controller.lock();
      controller.registerActivity();
      expect(pings, 2);
    });

    test('a atividade não faz o controller avisar mudança de modo', () {
      final controller = EditModeController()..enter();
      var changes = 0;
      controller.addListener(() => changes++);

      controller.registerActivity();

      expect(changes, 0);
    });
  });
}
