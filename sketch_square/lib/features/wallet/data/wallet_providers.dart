import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/providers.dart';
import '../domain/wallet_repository.dart';
import 'dio_wallet_repository.dart';

part 'wallet_providers.g.dart';

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) =>
    DioWalletRepository(ref.watch(dioProvider));
