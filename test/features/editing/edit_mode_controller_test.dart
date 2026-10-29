import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/editing/presentation/edit_mode_controller.dart';

void main() {
  group('EditModeController', () {
    test('começa em modo de uso', () {
      expect(EditModeController().isEditing, isFalse);
    });

    test('enter liga a edição e lock volta ao uso', () {
      final controller = EditModeController()..enter();
      expect(controller.isEditing, isTrue);

      controller.lock();
      expect(controller.isEditing, isFalse);
    });

    test('avisa os ouvintes só quando o modo muda', () {
      final controller = EditModeController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.lock(); // já está em uso
      expect(notifications, 0);
      controller.enter();
      expect(notifications, 1);
      controller.enter(); // já está em edição
      expect(notifications, 1);
      controller.lock();
      expect(notifications, 2);
    });
  });
}
