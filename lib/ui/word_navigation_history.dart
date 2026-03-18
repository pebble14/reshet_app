class WordNavigationHistoryEntry<T> {
  final String wordId;
  final String representativeSpelling;
  final String strongNumber;
  final T payload;

  const WordNavigationHistoryEntry({
    required this.wordId,
    required this.representativeSpelling,
    required this.strongNumber,
    required this.payload,
  });
}

class WordNavigationHistoryController<T> {
  final List<WordNavigationHistoryEntry<T>> _entries = [];
  int _currentIndex = -1;

  WordNavigationHistoryEntry<T>? get currentEntry {
    if (_currentIndex < 0 || _currentIndex >= _entries.length) {
      return null;
    }
    return _entries[_currentIndex];
  }

  bool get canGoBack => _currentIndex > 0;

  bool get canGoForward =>
      _currentIndex >= 0 && _currentIndex < _entries.length - 1;

  WordNavigationHistoryEntry<T>? get previousEntry =>
      canGoBack ? _entries[_currentIndex - 1] : null;

  WordNavigationHistoryEntry<T>? get nextEntry =>
      canGoForward ? _entries[_currentIndex + 1] : null;

  void reset(WordNavigationHistoryEntry<T> entry) {
    _entries
      ..clear()
      ..add(entry);
    _currentIndex = 0;
  }

  void push(WordNavigationHistoryEntry<T> entry) {
    if (_currentIndex >= 0 && _currentIndex < _entries.length - 1) {
      _entries.removeRange(_currentIndex + 1, _entries.length);
    }

    _entries.add(entry);
    _currentIndex = _entries.length - 1;
  }

  void replaceCurrent(WordNavigationHistoryEntry<T> entry) {
    if (_entries.isEmpty) {
      reset(entry);
      return;
    }

    _entries[_currentIndex] = entry;
  }

  WordNavigationHistoryEntry<T>? goBack() {
    if (!canGoBack) {
      return null;
    }

    _currentIndex--;
    return _entries[_currentIndex];
  }

  WordNavigationHistoryEntry<T>? goForward() {
    if (!canGoForward) {
      return null;
    }

    _currentIndex++;
    return _entries[_currentIndex];
  }
}
