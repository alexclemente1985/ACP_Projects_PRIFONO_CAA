import 'package:flutter_test/flutter_test.dart';
import 'package:prifono_caa/features/boards/data/in_memory_board_repository.dart';

import 'board_repository_contract.dart';

void main() {
  group('InMemoryBoardRepository', () {
    runBoardRepositoryContract(
      (now) async => InMemoryBoardRepository(now: now),
    );
  });
}
