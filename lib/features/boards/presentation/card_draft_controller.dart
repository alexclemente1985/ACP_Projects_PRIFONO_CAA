import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:prifono_caa/features/boards/domain/board_card.dart';
import 'package:prifono_caa/features/symbols/data/symbol_image_store.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_provider.dart';
import 'package:prifono_caa/features/symbols/domain/symbol_ref.dart';

/// Situação da imagem do pictograma escolhido (ADR-030).
enum SymbolDownloadStatus { none, downloading, ready, failed }

/// Rascunho de um card em edição: símbolo, estado do download e cor.
///
/// Rótulo e texto falado ficam nos TextEditingControllers da tela; eles
/// entram em [buildContent]. Sem widgets aqui: testável sem tela.
class CardDraftController extends ChangeNotifier {
  CardDraftController({required this._images, this._initial});

  final SymbolImageStore _images;
  final CardContent? _initial;

  late SymbolRef? _symbol = _initial?.symbol;
  late int? _backgroundColor = _initial?.backgroundColor;

  /// Símbolo que já vinha salvo conta como pronto: não baixamos de novo.
  late SymbolDownloadStatus _status = _symbol == null
      ? SymbolDownloadStatus.none
      : SymbolDownloadStatus.ready;

  SymbolErrorKind? _error;
  int _generation = 0;
  bool _disposed = false;

  SymbolRef? get symbol => _symbol;
  int? get backgroundColor => _backgroundColor;
  SymbolDownloadStatus get symbolStatus => _status;

  /// Tipo da falha do último download (null se não falhou ou se não foi de rede).
  SymbolErrorKind? get downloadError => _error;

  /// Só se salva com a imagem em mãos: baixando ou com falha, não.
  bool get canSave =>
      _status != SymbolDownloadStatus.downloading &&
      _status != SymbolDownloadStatus.failed;

  /// Arquivo local da imagem (pode ainda não existir).
  File? get imageFile {
    final ref = _symbol;
    if (ref == null) return null;
    return _images.fileFor(ref, size: SymbolImageSize.medium);
  }

  /// Escolhe um símbolo e baixa a imagem. Nunca lança: falha vira `failed`.
  Future<void> selectSymbol(SymbolRef ref) async {
    _symbol = ref;
    await _download(ref);
  }

  /// Tenta baixar de novo depois de uma falha.
  Future<void> retryDownload() async {
    final ref = _symbol;
    if (ref == null || _status != SymbolDownloadStatus.failed) return;
    await _download(ref);
  }

  void removeSymbol() {
    _generation++; // descarta qualquer download em andamento
    _symbol = null;
    _status = SymbolDownloadStatus.none;
    _error = null;
    notifyListeners();
  }

  void setBackgroundColor(int? argb) {
    if (argb == _backgroundColor) return;
    _backgroundColor = argb;
    notifyListeners();
  }

  /// Monta o conteúdo final. Lança [StateError] se ainda não pode salvar.
  CardContent buildContent({
    required String label,
    required String speechText,
  }) {
    if (!canSave) {
      throw StateError('O pictograma ainda não está pronto para salvar.');
    }
    final speech = speechText.trim();
    final initial = _initial;
    return CardContent(
      label: label.trim(),
      speechText: speech.isEmpty ? null : speech,
      symbol: _symbol,
      imagePath: initial?.imagePath,
      backgroundColor: _backgroundColor,
      linkBoardId: initial?.linkBoardId,
    );
  }

  Future<void> _download(SymbolRef ref) async {
    // Cada download ganha um número; resposta de número antigo é descartada
    // (a pessoa pode trocar de pictograma antes do primeiro terminar).
    final generation = ++_generation;
    _status = SymbolDownloadStatus.downloading;
    _error = null;
    notifyListeners();
    try {
      await _images.ensure(ref);
      if (_isStale(generation)) return;
      _status = SymbolDownloadStatus.ready;
    } on SymbolProviderException catch (error) {
      if (_isStale(generation)) return;
      _status = SymbolDownloadStatus.failed;
      _error = error.kind;
    } on Exception {
      if (_isStale(generation)) return;
      _status = SymbolDownloadStatus.failed;
      _error = null;
    }
    notifyListeners();
  }

  bool _isStale(int generation) => _disposed || generation != _generation;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
