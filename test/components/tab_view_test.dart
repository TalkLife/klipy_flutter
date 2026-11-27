import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klipy_flutter/klipy_flutter.dart';
import 'package:klipy_flutter/src/providers/providers.dart';
import 'package:provider/provider.dart';

void main() {
  const client = KlipyClient(apiKey: 'test');

  KlipyResponse emptyResponse() => KlipyResponse(results: const []);

  /// Pumps a GIFs-like tab (no categories) the way the sheet hosts it and
  /// returns the app bar provider that drives its search.
  Future<KlipyAppBarProvider> pumpTabView(
    WidgetTester tester, {
    required Future<KlipyResponse?> Function(String queryText) onLoad,
    KlipyTabViewStyle style = const KlipyTabViewStyle(),
  }) async {
    final view = KlipyTabView(
      client: client,
      showCategories: false,
      style: style,
      onLoad: (queryText, pos, limit, category) => onLoad(queryText),
    );
    final tab = KlipyTab(name: 'GIFs', view: view);
    final appBarProvider = KlipyAppBarProvider(
      '',
      Duration.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
    );
    addTearDown(appBarProvider.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MultiProvider(
            providers: [
              ChangeNotifierProvider<KlipyTabProvider>(
                create: (_) => KlipyTabProvider(
                  attributionType: KlipyAttributionType.poweredBy,
                  client: client,
                  selectedTab: tab,
                ),
              ),
              ChangeNotifierProvider<KlipyAppBarProvider>.value(
                value: appBarProvider,
              ),
              Provider<BoxConstraints>.value(
                value: const BoxConstraints(maxWidth: 400, maxHeight: 600),
              ),
              Provider<KlipyTab>.value(value: tab),
            ],
            child: view,
          ),
        ),
      ),
    );
    return appBarProvider;
  }

  /// Lets pending futures and the frames they schedule run. Not
  /// pumpAndSettle: the spinner animates forever.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }

  group('KlipyTabView empty results >', () {
    // KLIPY answers some searches ("knife") with 200 {"results": []}. The tab
    // showed its spinner for as long as the list was empty, so that search
    // looked like a load that never finished. ENG-39919.
    testWidgets('a search with no results ends in the empty state', (
      tester,
    ) async {
      final appBarProvider = await pumpTabView(
        tester,
        onLoad: (_) async => emptyResponse(),
      );
      appBarProvider.queryText = 'knife';
      await settle(tester);

      expect(find.text('No results found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('the spinner shows while the search is still loading', (
      tester,
    ) async {
      final pending = Completer<KlipyResponse?>();
      await pumpTabView(tester, onLoad: (_) => pending.future);
      await settle(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No results found'), findsNothing);

      pending.complete(emptyResponse());
      await settle(tester);

      expect(find.text('No results found'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a new search brings the spinner back until it answers', (
      tester,
    ) async {
      final pendingCat = Completer<KlipyResponse?>();
      final appBarProvider = await pumpTabView(
        tester,
        onLoad: (queryText) => queryText == 'cat'
            ? pendingCat.future
            : Future.value(emptyResponse()),
      );
      appBarProvider.queryText = 'knife';
      await settle(tester);
      expect(find.text('No results found'), findsOneWidget);

      appBarProvider.queryText = 'cat';
      await settle(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No results found'), findsNothing);

      pendingCat.complete(emptyResponse());
      await settle(tester);
    });

    // Typing fires a search per pause. A search that started while the
    // previous one was still in flight was never sent, so the tab kept
    // spinning for it once the older answer came back empty.
    testWidgets(
      'a search typed while another is in flight is still sent and answered',
      (tester) async {
        final requested = <String>[];
        final pendingKnif = Completer<KlipyResponse?>();
        final appBarProvider = await pumpTabView(
          tester,
          onLoad: (queryText) {
            requested.add(queryText);
            return queryText == 'knif'
                ? pendingKnif.future
                : Future.value(emptyResponse());
          },
        );
        await settle(tester);

        appBarProvider.queryText = 'knif';
        await settle(tester);
        appBarProvider.queryText = 'knife';
        await settle(tester);
        expect(requested, isNot(contains('knife')));

        pendingKnif.complete(emptyResponse());
        await settle(tester);

        expect(requested.last, 'knife');
        expect(find.text('No results found'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets('the empty state text comes from the style', (tester) async {
      final appBarProvider = await pumpTabView(
        tester,
        style: const KlipyTabViewStyle(noResultsText: 'Nothing here'),
        onLoad: (_) async => emptyResponse(),
      );
      appBarProvider.queryText = 'knife';
      await settle(tester);

      expect(find.text('Nothing here'), findsOneWidget);
    });
  });
}
