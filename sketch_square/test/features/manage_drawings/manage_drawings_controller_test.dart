import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/auth/presentation/current_user_provider.dart';
import 'package:sketch_square/features/manage_drawings/data/manage_drawings_providers.dart';
import 'package:sketch_square/features/manage_drawings/presentation/manage_drawings_controller.dart';

import 'fakes.dart';

void main() {
  late FakeManageDrawingsRepository repo;
  late ProviderContainer container;

  ProviderContainer build(FakeManageDrawingsRepository r) {
    repo = r;
    container = ProviderContainer(
      overrides: [
        manageDrawingsRepositoryProvider.overrideWithValue(r),
        currentUserIdProvider.overrideWithValue('u1'),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  Future<void> load(ManageFilter f) async {
    final sub = container.listen(
      managedDrawingsControllerProvider(f),
      (_, __) {},
    );
    addTearDown(sub.close);
    await container.read(managedDrawingsControllerProvider(f).future);
  }

  ManagedDrawingsController ctl(ManageFilter f) =>
      container.read(managedDrawingsControllerProvider(f).notifier);

  List<String> ids(ManageFilter f) => [
    for (final m
        in container
            .read(managedDrawingsControllerProvider(f))
            .requireValue
            .items)
      m.id,
  ];

  test('filter chips map to contract statuses', () {
    expect(ManageFilter.all.status, isNull);
    expect(ManageFilter.drafts.status, DrawingStatus.draft);
    expect(ManageFilter.rejected.status, DrawingStatus.failed);
    expect(ManageFilter.underReview.status, DrawingStatus.underReview);
  });

  test('All lists everything but REMOVED drawings', () async {
    build(
      FakeManageDrawingsRepository([
        managed('a'),
        managed('b', status: DrawingStatus.draft),
        managed('c', status: DrawingStatus.removed),
      ]),
    );
    await load(ManageFilter.all);
    expect(ids(ManageFilter.all), ['a', 'b']);
    expect(repo.listFilters, [null]);
  });

  test('a status filter is sent to the server', () async {
    build(
      FakeManageDrawingsRepository([
        managed('a'),
        managed('b', status: DrawingStatus.failed),
      ]),
    );
    await load(ManageFilter.rejected);
    expect(ids(ManageFilter.rejected), ['b']);
    expect(repo.listFilters, [DrawingStatus.failed]);
  });

  test(
    'loadMore appends pages without duplicates; failure waits for retry',
    () async {
      build(
        FakeManageDrawingsRepository([
          for (var i = 0; i < 5; i++) managed('d$i'),
        ], pageSize: 2),
      );
      await load(ManageFilter.all);
      expect(ids(ManageFilter.all), ['d0', 'd1']);

      repo.failNext('list', apiError(ApiErrorCodes.network, 'offline'));
      await ctl(ManageFilter.all).loadMore();
      var s =
          container
              .read(managedDrawingsControllerProvider(ManageFilter.all))
              .requireValue;
      expect(s.loadMoreError?.message, 'offline');
      expect(s.items, hasLength(2));

      await ctl(ManageFilter.all).loadMore(); // no auto-retry
      expect(repo.count('list'), 2);

      await ctl(ManageFilter.all).loadMore(retry: true);
      await ctl(ManageFilter.all).loadMore();
      s =
          container
              .read(managedDrawingsControllerProvider(ManageFilter.all))
              .requireValue;
      expect(ids(ManageFilter.all), ['d0', 'd1', 'd2', 'd3', 'd4']);
      expect(s.hasMore, isFalse);
    },
  );

  test(
    'first page failure surfaces as an error and recovers on refresh',
    () async {
      build(FakeManageDrawingsRepository([managed('a')]));
      repo.failNext('list', apiError(ApiErrorCodes.network, 'offline'));
      final sub = container.listen(
        managedDrawingsControllerProvider(ManageFilter.all),
        (_, __) {},
      );
      addTearDown(sub.close);
      await expectLater(
        container.read(
          managedDrawingsControllerProvider(ManageFilter.all).future,
        ),
        throwsA(isA<ApiException>()),
      );
      await ctl(ManageFilter.all).refresh();
      expect(ids(ManageFilter.all), ['a']);
    },
  );

  test('remove deletes on the server and drops the row', () async {
    build(FakeManageDrawingsRepository([managed('a'), managed('b')]));
    await load(ManageFilter.all);
    await ctl(ManageFilter.all).remove('a');
    expect(repo.count('delete'), 1);
    expect(ids(ManageFilter.all), ['b']);
  });

  test('a failed remove keeps the row and rethrows', () async {
    build(FakeManageDrawingsRepository([managed('a')]));
    await load(ManageFilter.all);
    repo.failNext('delete', apiError(ApiErrorCodes.network, 'offline'));
    await expectLater(
      ctl(ManageFilter.all).remove('a'),
      throwsA(isA<ApiException>()),
    );
    expect(ids(ManageFilter.all), ['a']);
  });

  test('updatePublished sends the fields and updates the row', () async {
    build(FakeManageDrawingsRepository([managed('a')]));
    await load(ManageFilter.all);
    await ctl(ManageFilter.all).updatePublished(
      'a',
      title: ' Better title ',
      description: 'A much better description of this plan',
      pricePaise: 79900,
    );
    expect(repo.updates.single['pricePaise'], 79900);
    final item =
        container
            .read(managedDrawingsControllerProvider(ManageFilter.all))
            .requireValue
            .items
            .single;
    expect(item.drawing.title, 'Better title');
    expect(item.drawing.pricePaise, 79900);
    expect(item.stats.viewCount, 120); // stats untouched
  });
}
