/// Lançada quando uma operação referencia um registro que não existe.
class NotFoundException implements Exception {
  const NotFoundException(this.entity, this.id);

  final String entity;
  final Object id;

  @override
  String toString() => 'NotFoundException: $entity $id não encontrado';
}