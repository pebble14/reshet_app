import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/word_repository.dart';
import '../domain/home/home_search_result_display_item.dart';
import 'word_search_query.dart';

class MobileWordSearchScreen extends StatefulWidget {
  final WordSearchQueryRunner? queryRunner;

  const MobileWordSearchScreen({super.key, this.queryRunner});

  @override
  State<MobileWordSearchScreen> createState() => _MobileWordSearchScreenState();
}

class _MobileWordSearchScreenState extends State<MobileWordSearchScreen> {
  final WordRepository _repository = WordRepository();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode(
    debugLabel: 'mobile-global-search',
  );

  Future<List<HomeSearchResultDisplayItem>>? _searchFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  Future<List<HomeSearchResultDisplayItem>> _query(String query) {
    final queryRunner = widget.queryRunner;
    if (queryRunner != null) {
      return queryRunner(query);
    }

    return runWordSearchQuery(repository: _repository, query: query);
  }

  void _runSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchFuture = null;
      });
      return;
    }

    setState(() {
      _searchFuture = _query(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchFuture = null;
    });
    _searchFocusNode.requestFocus();
  }

  void _select(
    HomeSearchResultDisplayItem item,
    WordSearchDestination destination,
  ) {
    Navigator.pop(
      context,
      WordSearchSelection(wordId: item.wordId, destination: destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('검색')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('mobile-global-search-field'),
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: '검색 (표기/의미/스트롱 번호)',
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  IconButton(
                    key: const Key('mobile-global-search-submit'),
                    onPressed: _runSearch,
                    icon: const Icon(Icons.search),
                    tooltip: '검색',
                  ),
                  IconButton(
                    key: const Key('mobile-global-search-clear'),
                    onPressed: _clearSearch,
                    icon: const Icon(Icons.clear),
                    tooltip: '초기화',
                  ),
                ],
              ),
            ),
            Expanded(child: _buildResultSurface()),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSurface() {
    final searchFuture = _searchFuture;
    if (searchFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<HomeSearchResultDisplayItem>>(
      future: searchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('에러 발생: ${snapshot.error}'));
        }

        final words = snapshot.data ?? const <HomeSearchResultDisplayItem>[];
        if (words.isEmpty) {
          return const Center(child: Text('검색 결과 없음'));
        }

        return ListView.builder(
          key: const Key('mobile-global-search-result-list'),
          itemCount: words.length,
          itemBuilder: (context, index) {
            final item = words[index];
            final subtitle = item.subtitleMeaning ?? '';

            return ListTile(
              key: ValueKey('mobile-global-search-result-${item.wordId}'),
              title: Text(
                buildWordSearchResultTitle(item),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: subtitle.isEmpty
                  ? null
                  : Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: ValueKey('mobile-global-search-detail-${item.wordId}'),
                    icon: const Icon(Icons.article_outlined),
                    tooltip: '상세',
                    onPressed: () =>
                        _select(item, WordSearchDestination.detail),
                  ),
                  IconButton(
                    key: ValueKey('mobile-global-search-graph-${item.wordId}'),
                    icon: const Icon(Icons.hub_outlined),
                    tooltip: '그래프',
                    onPressed: () => _select(item, WordSearchDestination.graph),
                  ),
                ],
              ),
              onTap: () => _select(item, WordSearchDestination.detail),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
