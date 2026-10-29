import 'package:flutter/foundation.dart';

/// Modo de USO (padrão) ou de EDIÇÃO do app inteiro (ADR-033, E5-3).
///
/// Em uso, a pessoa só fala: tocar nos cards, montar frases. Criar, editar e
/// excluir (pranchas e cards) só em edição, que se liga segurando o cadeado e
/// se desliga sozinha quando o app vai para segundo plano. O app sempre abre
/// em uso: este estado NÃO é gravado.
class EditModeController extends ChangeNotifier {
  bool _editing = false;

  bool get isEditing => _editing;

  /// Liga a edição. (Na E5-5 o PIN, se houver, é pedido ANTES de chamar isto.)
  void enter() {
    if (_editing) return;
    _editing = true;
    notifyListeners();
  }

  /// Volta ao modo de uso.
  void lock() {
    if (!_editing) return;
    _editing = false;
    notifyListeners();
  }
}
