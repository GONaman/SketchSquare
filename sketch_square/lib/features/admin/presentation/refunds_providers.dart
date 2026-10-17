import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../data/dio_admin_refunds_repository.dart';
import '../domain/admin_purchase.dart';
import '../domain/admin_refunds_repository.dart';

final adminRefundsRepositoryProvider = Provider<AdminRefundsRepository>(
  (ref) => DioAdminRefundsRepository(ref.watch(dioProvider)),
);

/// Purchase detail (with the seller's balance); refetched after a refund.
final adminPurchaseProvider = FutureProvider.autoDispose
    .family<AdminPurchase, String>(
      (ref, id) => ref.watch(adminRefundsRepositoryProvider).purchase(id),
    );

/// Bumped when a refund is booked so the open list reloads.
final refundsVersionProvider = StateProvider<int>((_) => 0);
