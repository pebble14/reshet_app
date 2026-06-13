sealed class WordDetailRouteResult {
  const WordDetailRouteResult();
}

final class WordDetailDeletedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailDeletedResult({required this.wordId});
}

final class WordDetailEditRequestedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailEditRequestedResult({required this.wordId});
}

final class WordDetailGraphRequestedResult extends WordDetailRouteResult {
  final String wordId;

  const WordDetailGraphRequestedResult({required this.wordId});
}
