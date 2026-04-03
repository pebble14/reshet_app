import '../../data/repositories/word_repository.dart';
import 'word_write_models.dart';

class WordWriteService {
  final WordRepository _repository;

  WordWriteService({WordRepository? repository})
    : _repository = repository ?? WordRepository();

  Future<WordWriteResult> execute(WordWriteCommand command) async {
    if (command is CreateWordCommand) {
      final payload = command.payload;
      final newId = await _repository.generateNextWordId(
        language: payload.language,
        strongNumber: payload.strongNumber,
      );

      await _repository.createWord(id: newId, payload: payload);
      return WordWriteResult(action: WordWriteAction.create, wordId: newId);
    }

    if (command is UpdateWordCommand) {
      await _repository.updateWord(
        id: command.wordId,
        payload: command.payload,
      );
      return WordWriteResult(
        action: WordWriteAction.update,
        wordId: command.wordId,
      );
    }

    final deleteCommand = command as DeleteWordCommand;
    await _repository.deleteWord(deleteCommand.wordId);
    return WordWriteResult(
      action: WordWriteAction.delete,
      wordId: deleteCommand.wordId,
    );
  }
}
