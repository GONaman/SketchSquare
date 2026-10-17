import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/cursor_page.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';

class DioWalletRepository implements WalletRepository {
  DioWalletRepository(this._dio);
  final Dio _dio;

  Map<String, Object> _paging(String? cursor, int? limit) => {
    if (cursor != null) 'cursor': cursor,
    if (limit != null) 'limit': limit,
  };

  @override
  Future<WalletSummary> summary() async {
    try {
      final res = await _dio.get<Object?>('/wallet');
      return WalletSummary.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<LedgerEntry>> ledger({String? cursor, int? limit}) async {
    try {
      final res = await _dio.get<Object?>(
        '/wallet/ledger',
        queryParameters: _paging(cursor, limit),
      );
      return CursorPage.fromJson(
        res.data! as Map<String, dynamic>,
        LedgerEntry.fromJson,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<BankAccountInfo> saveBankAccount({
    required String holderName,
    required String ifsc,
    required String accountNumber,
  }) async {
    try {
      final res = await _dio.post<Object?>(
        '/wallet/bank-account',
        data: {
          'holderName': holderName,
          'ifsc': ifsc,
          'accountNumber': accountNumber,
        },
      );
      return BankAccountInfo.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<Withdrawal> requestWithdrawal(int amountPaise) async {
    try {
      final res = await _dio.post<Object?>(
        '/wallet/withdrawals',
        data: {'amountPaise': amountPaise},
      );
      return Withdrawal.fromJson(res.data! as Map<String, dynamic>);
    } catch (e) {
      throw toApiException(e);
    }
  }

  @override
  Future<CursorPage<Withdrawal>> withdrawals({
    String? cursor,
    int? limit,
  }) async {
    try {
      final res = await _dio.get<Object?>(
        '/wallet/withdrawals',
        queryParameters: _paging(cursor, limit),
      );
      return CursorPage.fromJson(
        res.data! as Map<String, dynamic>,
        Withdrawal.fromJson,
      );
    } catch (e) {
      throw toApiException(e);
    }
  }
}
