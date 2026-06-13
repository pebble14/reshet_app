sealed class WordDetailRouteResult {
  const WordDetailRouteResult();
}

final class WordDetailDeletedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailDeletedResult({required this.wordId});
}
