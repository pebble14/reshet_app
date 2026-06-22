import '../data/repositories/word_repository.dart';
import '../domain/expression/home_word_display_summary.dart';
import '../domain/home/home_search_result_display_item.dart';

typedef WordSearchQueryRunner =
    Future<List<HomeSearchResultDisplayItem>> Function(String query);

enum WordSearchDestination { detail, graph }

class WordSearchSelection {
  final String wordId;
  final WordSearchDestination destination;

  const WordSearchSelection({required this.wordId, required this.destination});
}

Future<List<HomeSearchResultDisplayItem>> runWordSearchQuery({
  required WordRepository repository,
  required String query,
  int limit = 200,
}) async {
  final keyword = query.trim();
  if (keyword.isEmpty) {
    return const [];
  }

  if (_isStrongExactQuery(keyword)) {
    final exactMatches = await repository.searchStrongExactMap(
      keyword,
      limit: limit,
    );
    if (exactMatches.isNotEmpty) {
      return exactMatches;
    }
  }

  return repository.searchWordsMap(keyword, limit: limit);
}

HomeWordDisplaySummary buildWordSearchResultSummary(
  HomeSearchResultDisplayItem item,
) {
  return HomeWordDisplaySummary(
    representativeSpelling: item.representativeSpelling ?? '',
    representativeTransliteration: item.representativeTransliteration ?? '',
    representativePronunciation: item.representativePronunciation ?? '',
  );
}

String buildWordSearchResultTitle(HomeSearchResultDisplayItem item) {
  return buildSearchResultTitle(
    strong: item.displayStrongNumber ?? '',
    summary: buildWordSearchResultSummary(item),
  );
}

bool _isStrongExactQuery(String input) {
  return RegExp(r'^[HhGg]\d+$').hasMatch(input.trim());
}
