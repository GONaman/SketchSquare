import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/purchases_repositories.dart';
import 'dio_purchases_repositories.dart';

part 'purchases_providers.g.dart';

@Riverpod(keepAlive: true)
PurchasesRepository purchasesRepository(Ref ref) =>
    DioPurchasesRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
ReviewRepository reviewRepository(Ref ref) =>
    DioReviewRepository(ref.watch(dioProvider));

@Riverpod(keepAlive: true)
FileDownloader fileDownloader(Ref ref) => HttpFileDownloader();

@Riverpod(keepAlive: true)
FileHandler fileHandler(Ref ref) => PlatformFileHandler();
