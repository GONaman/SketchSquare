import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/city_count.dart';
import '../domain/drawing_actions_repository.dart';
import '../domain/drawing_detail.dart';
import '../domain/drawing_summary.dart';
import '../domain/drawings_repository.dart';
import 'dio_drawing_actions_repository.dart';
import 'dio_drawings_repository.dart';

part 'drawings_providers.g.dart';

@Riverpod(keepAlive: true)
DrawingsRepository drawingsRepository(Ref ref) =>
    DioDrawingsRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
DrawingActionsRepository drawingActionsRepository(Ref ref) =>
    DioDrawingActionsRepository(ref.watch(dioProvider));

/// Active categories for chips and the filter sheet. Cached for the session.
@Riverpod(keepAlive: true)
Future<List<CategoryRef>> categories(Ref ref) =>
    ref.watch(drawingsRepositoryProvider).listCategories();

/// Cities that have published drawings (filter sheet, Featured city picker).
@Riverpod(keepAlive: true)
Future<List<CityCount>> cities(Ref ref) =>
    ref.watch(drawingsRepositoryProvider).listCities();

@riverpod
Future<DrawingDetail> drawingDetail(Ref ref, String id) =>
    ref.watch(drawingsRepositoryProvider).getDrawing(id);
