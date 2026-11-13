import 'package:flutter/foundation.dart';

/// Modo de USO (padrão) ou de EDIÇÃO do app inteiro (ADR-033, E5-3).
///
/// Em uso, a pessoa só fala: tocar nos cards, montar frases. Criar, editar e
/// excluir (pranchas e cards) só em edição, que se liga segurando o cadeado (ou
/// tocando nele, com PIN) e se desliga sozinha quando o app vai para segundo
/// plano ou fica um tempo sem toques (E6-5). O app sempre abre em uso: este
/// estado NÃO é gravado.
class EditModeController extends ChangeNotifier {
  bool _editing = false;
  bool _lastLockWasIdle = false;
  final _Activity _activity = _Activity();

  bool get isEditing => _editing;

  /// A última vez que a edição travou foi por inatividade? Quem mostra o aviso
  /// ("Edição bloqueada por inatividade") consulta isto quando o estado muda.
  bool get lastLockWasIdle => _lastLockWasIdle;

  /// Avisa sempre que há atividade (toque, tecla, digitação) ENQUANTO se edita.
  /// O vigia de inatividade reinicia a contagem a cada aviso.
  Listenable get activity => _activity;

  /// Liga a edição. (Na E5-5 o PIN, se houver, é pedido ANTES de chamar isto.)
  void enter() {
    if (_editing) return;
    _editing = true;
    _lastLockWasIdle = false;
    notifyListeners();
  }

  /// Volta ao modo de uso (cadeado, segundo plano).
  void lock() => _lock(idle: false);

  /// Volta ao modo de uso porque ficou tempo demais sem toques.
  void lockForInactivity() => _lock(idle: true);

  /// Registra que a pessoa está mexendo no app. Fora da edição não faz nada: o
  /// modo de uso não tem contagem.
  void registerActivity() {
    if (!_editing) return;
    _activity.ping();
  }

  void _lock({required bool idle}) {
    if (!_editing) return;
    _editing = false;
    _lastLockWasIdle = idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _activity.dispose();
    super.dispose();
  }
}

/// Canal só de "aconteceu algo" (sem estado), para [EditModeController.activity].
class _Activity extends ChangeNotifier {
  void ping() => notifyListeners();
}
