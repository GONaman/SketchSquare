import 'package:go_router/go_router.dart';

import '../../../core/router/placeholder_detail_route.dart';
import '../../../core/router/routes.dart';
import '../../purchases/presentation/purchases_screen.dart';
import '../../wallet/presentation/bank_account_screen.dart';
import '../../wallet/presentation/payouts_screen.dart';
import '../../wallet/presentation/wallet_screen.dart';
import 'edit_contact_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

/// Routes of the Profile tab; registered as one branch in `core/router/app_router.dart`.
final profileRoutes = <RouteBase>[
  GoRoute(
    path: AppRoutes.profile,
    builder: (_, __) => const ProfileScreen(),
    routes: [
      GoRoute(path: 'purchases', builder: (_, __) => const PurchasesScreen()),
      GoRoute(path: 'edit', builder: (_, __) => const EditContactScreen()),
      GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
      GoRoute(
        path: 'wallet',
        builder: (_, __) => const WalletScreen(),
        routes: [
          GoRoute(
            path: 'bank-account',
            builder: (_, __) => const BankAccountScreen(),
          ),
          GoRoute(path: 'payouts', builder: (_, __) => const PayoutsScreen()),
        ],
      ),
      placeholderDetailRoute,
    ],
  ),
];
