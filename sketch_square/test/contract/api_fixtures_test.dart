import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketch_square/core/network/api_exception.dart';
import 'package:sketch_square/core/network/dio_client.dart';
import 'package:sketch_square/core/storage/secure_storage.dart';
import 'package:sketch_square/core/storage/token_store.dart';
import 'package:sketch_square/features/admin/data/dio_admin_repository.dart';
import 'package:sketch_square/features/architects/data/dio_architects_repository.dart';
import 'package:sketch_square/features/auth/data/dio_auth_repository.dart';
import 'package:sketch_square/features/auth/domain/user.dart';
import 'package:sketch_square/features/basket/data/dio_basket_repositories.dart';
import 'package:sketch_square/features/basket/domain/checkout_models.dart';
import 'package:sketch_square/features/drawings/data/dio_drawing_actions_repository.dart';
import 'package:sketch_square/features/drawings/data/dio_drawings_repository.dart';
import 'package:sketch_square/features/drawings/domain/drawing_detail.dart';
import 'package:sketch_square/features/drawings/domain/drawing_search_query.dart';
import 'package:sketch_square/features/drawings/domain/drawing_summary.dart';
import 'package:sketch_square/features/drawings/domain/plot_size.dart';
import 'package:sketch_square/features/drawings/domain/sheet.dart';
import 'package:sketch_square/features/manage_drawings/data/dio_manage_drawings_repository.dart';
import 'package:sketch_square/features/profile/data/dio_profile_repository.dart';
import 'package:sketch_square/features/profile/domain/profile_repository.dart';
import 'package:sketch_square/features/purchases/data/dio_purchases_repositories.dart';
import 'package:sketch_square/features/purchases/domain/purchase_models.dart';
import 'package:sketch_square/features/upload/data/dio_upload_repository.dart';
import 'package:sketch_square/features/upload/domain/drawing_form.dart';
import 'package:sketch_square/features/verification/data/dio_verification_repository.dart';
import 'package:sketch_square/features/verification/domain/verification_request.dart';
import 'package:sketch_square/features/wallet/data/dio_wallet_repository.dart';
import 'package:sketch_square/features/wallet/domain/wallet_models.dart';

import '../helpers/scripted_adapter.dart';

/// Replays JSON captured from the REAL backend by `backend/scripts/smoke.ts`
/// (`npm run smoke -- --capture ../sketch_square/test/fixtures/api`) through the
/// real Dio repositories and models, so a backend/Flutter drift fails here.
Object? fx(String name) =>
    jsonDecode(File('test/fixtures/api/$name.json').readAsStringSync());

void main() {
  late ScriptedAdapter adapter;
  late Dio dio;
  late Map<String, Object?> routes;

  ResponseBody reply(RequestOptions o) {
    final key = '${o.method} ${o.path}';
    if (!routes.containsKey(key)) {
      throw StateError('No fixture route for $key');
    }
    final body = routes[key];
    return jsonResponse(body, body == null ? 204 : 200);
  }

  RequestOptions last() => adapter.requests.last;

  Dio newDio(ScriptedAdapter a) => createDio(
    tokenStore: SecureTokenStore(InMemorySecureStorage()),
    baseUrl: 'http://test',
    httpClientAdapter: a,
  );

  setUp(() {
    routes = {};
    adapter = ScriptedAdapter(reply);
    dio = newDio(adapter);
  });

  group('auth + profile', () {
    test('signup / login / refresh / me parse real responses', () async {
      routes['POST /auth/signup'] = fx('auth_signup');
      routes['POST /auth/login'] = fx('auth_login');
      routes['POST /auth/refresh'] = fx('auth_refresh');
      routes['GET /me'] = fx('me');
      final repo = DioAuthRepository(dio);

      final s = await repo.signup(
        email: 'a@b.co',
        password: 'Password1',
        fullName: 'A',
        phone: '+919800000000',
        address: 'x',
        city: 'Pune',
      );
      expect(s.user.role, UserRole.architect);
      expect(s.tokens.accessToken, isNotEmpty);

      final l = await repo.login(email: 'a@b.co', password: 'Password1');
      expect(l.user.verificationStatus, VerificationStatus.approved);
      expect(l.user.freeDownloadLimit, 20);
      expect(l.tokens.expiresIn, 900);

      expect((await repo.refresh('rt')).refreshToken, isNotEmpty);
      expect((await repo.me()).email, contains('@'));
    });

    test('PATCH /me and the avatar upload-url / PUT / confirm flow', () async {
      routes['PATCH /me'] = fx('me_patch');
      routes['POST /me/avatar/upload-url'] = fx('avatar_upload_url');
      routes['POST /me/avatar/confirm'] = fx('avatar_confirm');
      final storageAdapter = ScriptedAdapter((_) => jsonResponse(null, 200));
      final storage = Dio()..httpClientAdapter = storageAdapter;
      final repo = DioProfileRepository(dio, storageDio: storage);

      final u = await repo.updateContact(phone: '+919811111111', city: 'Pune');
      expect(u.phone, '+919811111111');

      final upload = fx('avatar_upload_url') as Map<String, dynamic>;
      final withAvatar = await repo.uploadAvatar(
        AvatarImage(
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: 'image/png',
        ),
      );
      expect(withAvatar.avatarUrl, isNotNull);

      final put = storageAdapter.requests.single;
      expect(put.uri.toString(), upload['uploadUrl']);
      expect(put.headers['content-type'], 'image/png');
      expect(
        put.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(last().data, {'objectKey': upload['objectKey']});
    });
  });

  group('verification + admin', () {
    test('submit is multipart and parses VerificationRequest', () async {
      routes['POST /verification'] = fx('verification_submit');
      routes['GET /verification/me'] = fx('verification_me');
      final repo = DioVerificationRepository(dio);
      final v = await repo.submit(
        coaRegistrationNumber: 'CA/2020/1',
        document: VerificationDocument(
          fileName: 'coa.pdf',
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
      );
      expect(v.status, VerificationStatus.pending);
      final form = last().data as FormData;
      expect(form.fields.map((f) => f.key), contains('coaRegistrationNumber'));
      expect(form.files.single.key, 'document');
      expect((await repo.mine())!.id, v.id);
    });

    test('admin queue, detail and approve', () async {
      final detail = fx('admin_verification_detail') as Map<String, dynamic>;
      routes['GET /admin/verifications'] = fx('admin_verifications');
      routes['GET /admin/verifications/${detail['id']}'] = detail;
      routes['POST /admin/verifications/${detail['id']}/approve'] = fx(
        'admin_approve',
      );
      final repo = DioAdminRepository(dio);

      expect((await repo.verifications()).items, isNotEmpty);
      expect(last().queryParameters['status'], 'PENDING');
      final d = await repo.verification(detail['id'] as String);
      expect(d.documentUrl, isNotNull);
      expect(d.user.email, contains('@'));
      await repo.approve(d.id);
    });
  });

  group('drawings', () {
    test('search pages parse and params are accepted by the backend', () async {
      final repo = DioDrawingsRepository(dio);

      routes['GET /drawings/search'] = fx('search_text');
      expect(
        (await repo.search(const DrawingSearchQuery(q: 'villa'))).items,
        isNotEmpty,
      );
      expect(last().queryParameters['q'], 'villa');

      routes['GET /drawings/search'] = fx('search_size');
      final size = await repo.search(
        const DrawingSearchQuery(
          length: 30,
          breadth: 40,
          unit: LengthUnit.m,
          tolerancePct: 15,
        ),
      );
      expect(size.items.first.sizeMatch, isNotNull);
      expect(last().queryParameters, containsPair('unit', 'm'));

      routes['GET /drawings/search'] = fx('search_filtered');
      await repo.search(
        const DrawingSearchQuery(
          priceType: PriceType.paid,
          sort: DrawingSort.priceAsc,
        ),
      );
    });

    test('every sort the app sends is one the backend declares', () {
      const backend = {
        'relevance',
        'price_asc',
        'price_desc',
        'drawing_rating',
        'architect_rating',
        'newest',
        'popularity',
        'size_match',
      };
      expect(
        DrawingSort.values.map((s) => s.apiValue).toSet().difference(backend),
        isEmpty,
      );
    });

    test(
      'detail (buyer / seller / free) parses sheets, viewer, reviews',
      () async {
        final repo = DioDrawingsRepository(dio);
        Future<DrawingDetail> load(String name) async {
          final json = fx(name) as Map<String, dynamic>;
          routes['GET /drawings/${json['id']}'] = json;
          return repo.getDrawing(json['id'] as String);
        }

        final buyer = await load('drawing_detail_buyer');
        expect(buyer.summary.status, DrawingStatus.published);
        expect(buyer.sheets, isNotEmpty);
        expect(buyer.viewer.isOwner, isFalse);
        expect(buyer.previewUrls, isNotEmpty);

        expect((await load('drawing_detail_seller')).viewer.isOwner, isTrue);
        final free = await load('drawing_detail_free');
        expect(free.summary.isFree, isTrue);
        expect(free.summary.pricePaise, 0);
      },
    );

    test('reviews, categories, cities, category request', () async {
      routes['GET /drawings/d1/reviews'] = fx('reviews');
      routes['GET /categories'] = fx('categories');
      routes['GET /cities'] = fx('cities');
      routes['POST /category-requests'] = fx('category_request');
      final repo = DioDrawingsRepository(dio);
      expect((await repo.listReviews('d1')).items, isNotEmpty);
      expect((await repo.listCategories()).first.slug, isNotEmpty);
      expect((await repo.listCities()).first.count, greaterThan(0));
      await repo.requestCategory('Something');
    });

    test('architects: top, profile, drawings', () async {
      final profile = fx('architect_profile') as Map<String, dynamic>;
      final id = (profile['architect'] as Map)['id'] as String;
      routes['GET /architects/top'] = fx('architects_top');
      routes['GET /architects/$id'] = profile;
      routes['GET /architects/$id/drawings'] = fx('architect_drawings');
      final repo = DioArchitectsRepository(dio);
      expect((await repo.top()).first.drawingCount, greaterThan(0));
      expect((await repo.getArchitect(id)).architect.id, id);
      expect((await repo.listDrawings(id)).items, isNotEmpty);
    });

    test('favorites + add-to-cart use the contract verbs', () async {
      routes['PUT /drawings/d1/favorite'] = null;
      routes['DELETE /drawings/d1/favorite'] = null;
      routes['POST /cart'] = fx('cart_add');
      final repo = DioDrawingActionsRepository(dio);
      await repo.setFavorite('d1', favorite: true);
      expect(last().method, 'PUT');
      await repo.setFavorite('d1', favorite: false);
      expect(last().method, 'DELETE');
      await repo.addToCart('d1');
      expect(last().data, {'drawingId': 'd1'});
    });
  });

  group('upload (seller)', () {
    const form = DrawingForm(
      title: 'Villa',
      description: 'Nice',
      categoryId: 'c1',
      city: 'Pune',
      plotLength: 40,
      plotBreadth: 30,
      floors: 2,
      bedrooms: 3,
      facing: 'NE',
      tags: ['modern'],
      pricePaise: 250000,
    );

    test(
      'bedrooms + tags are sent by default (UPLOAD_SEND_EXTENDED_METADATA)',
      () async {
        routes['POST /drawings'] = fx('drawing_create');
        final repo = DioUploadRepository(
          dio,
          sendExtendedMetadata: UploadConfig.sendExtendedMetadata,
        );
        final rec = await repo.createDraft(form);
        expect(rec.status, DrawingStatus.draft);
        expect(last().data, containsPair('bedrooms', 3));
        expect(last().data, containsPair('tags', ['modern']));
        expect(last().data, containsPair('unit', 'ft'));
      },
    );

    test('draft PATCH, sheet upload-url, register, publish parse', () async {
      final patched = fx('drawing_patch_draft') as Map<String, dynamic>;
      routes['PATCH /drawings/d1'] = patched;
      routes['POST /drawings/d1/sheets/upload-url'] = fx('drawing_upload_url');
      routes['POST /drawings/d1/sheets'] = fx('drawing_sheet');
      routes['POST /drawings/d1/publish'] = fx('drawing_publish');
      final repo = DioUploadRepository(dio, sendExtendedMetadata: true);

      final rec = await repo.updateDraft('d1', form);
      expect(rec.title, patched['title']);
      expect(rec.plotAreaSqft, greaterThan(0));

      final target = await repo.requestSheetUpload(
        'd1',
        fileName: 'plan.png',
        contentType: 'image/png',
        sizeBytes: 10,
      );
      expect(target.headers['Content-Type'], 'image/png');
      expect(target.objectKey, startsWith('drawings/'));

      final sheet = await repo.registerSheet(
        'd1',
        type: SheetType.architectural,
        objectKey: target.objectKey,
        isPreview: true,
        fileName: 'plan.png',
        sizeBytes: 10,
      );
      expect(sheet.type, SheetType.architectural);
      expect(sheet.isPreview, isTrue);

      expect(await repo.publish('d1'), DrawingStatus.processing);
    });

    test('manage drawings list + published edit', () async {
      routes['GET /me/drawings'] = fx('me_drawings');
      routes['PATCH /drawings/d1'] = fx('drawing_patch_published');
      final repo = DioManageDrawingsRepository(dio);
      final page = await repo.list(status: DrawingStatus.published);
      expect(page.items, isNotEmpty);
      expect(last().queryParameters['status'], 'PUBLISHED');
      await repo.updatePublished(
        'd1',
        title: 't',
        description: 'd',
        pricePaise: 100,
      );
    });
  });

  group('commerce', () {
    test('cart + checkout (stub) + status', () async {
      routes['GET /cart'] = fx('cart');
      routes['POST /checkout'] = fx('checkout');
      routes['POST /checkout/verify'] = fx('checkout_verify');
      routes['POST /checkout/stub-complete'] = fx('checkout_stub_complete');
      routes['GET /checkout/status'] = fx('checkout_status_paid');
      final cart = await DioCartRepository(dio).getCart();
      expect(cart.totalPaise, cart.computedTotalPaise);

      final repo = DioCheckoutRepository(dio);
      final order = await repo.createOrder();
      expect(order.isStub, isTrue);
      expect(order.amountPaise, greaterThan(0));
      expect(order.purchaseIds, isNotEmpty);
      expect(await repo.stubComplete(order.orderId), OrderStatus.paid);
      expect(await repo.status(order.orderId), OrderStatus.paid);
      expect(
        await repo.verify(
          const PaymentConfirmation(
            razorpayOrderId: 'o',
            razorpayPaymentId: 'p',
            razorpaySignature: 's',
          ),
        ),
        OrderStatus.paid,
      );
    });

    test('purchases, download link, review', () async {
      routes['GET /me/purchases'] = fx('purchases');
      routes['GET /drawings/d1/download'] = fx('download');
      routes['GET /drawings/d2/download'] = fx('download_free');
      routes['PUT /drawings/d1/review'] = fx('review');
      final repo = DioPurchasesRepository(dio);
      final page = await repo.list();
      expect(page.items, isNotEmpty);
      expect(page.items.first.sheets, isNotEmpty);
      expect(page.items.map((p) => p.kind), contains(PurchaseKind.paid));

      final link = await repo.downloadLink('d1', 's1');
      expect(link.url, startsWith('http'));
      expect(link.fileName, isNotEmpty);
      expect(last().queryParameters, {'sheetId': 's1'});
      expect((await repo.downloadLink('d2', 's1')).fileName, isNotEmpty);

      final review = await DioReviewRepository(
        dio,
      ).submit('d1', rating: 4, comment: 'Great plan');
      expect(review.rating, 4);
      expect(last().data, {'rating': 4, 'comment': 'Great plan'});
    });
  });

  group('wallet', () {
    test('summary, ledger, bank account, withdrawals', () async {
      final repo = DioWalletRepository(dio);

      routes['GET /wallet'] = fx('wallet_initial');
      final initial = await repo.summary();
      expect(initial.bankAccount, isNull);
      expect(initial.balancePaise, greaterThan(0));
      expect(initial.pendingWithdrawalPaise, 0);

      routes['GET /wallet'] = fx('wallet_after_withdrawal');
      final after = await repo.summary();
      expect(after.pendingWithdrawalPaise, greaterThan(0));
      expect(after.bankAccount!.accountNumberLast4, hasLength(4));

      routes['GET /wallet/ledger'] = fx('wallet_ledger_full');
      final ledger = await repo.ledger();
      expect(
        ledger.items.map((e) => e.entryType),
        isNot(contains(LedgerEntryType.other)),
        reason: 'unknown ledger entryType from backend',
      );
      expect(
        ledger.items
            .where((e) => e.entryType == LedgerEntryType.withdrawal)
            .every((e) => !e.isCredit),
        isTrue,
      );

      routes['POST /wallet/bank-account'] = fx('wallet_bank_account');
      final bank = await repo.saveBankAccount(
        holderName: 'A',
        ifsc: 'HDFC0001234',
        accountNumber: '123456789012',
      );
      expect(bank.accountNumberLast4, '9012');

      routes['POST /wallet/withdrawals'] = fx('wallet_withdrawal');
      final w = await repo.requestWithdrawal(50000);
      expect(w.status, WithdrawalStatus.requested);
      expect(last().data, {'amountPaise': 50000});

      routes['GET /wallet/withdrawals'] = fx('wallet_withdrawals');
      expect((await repo.withdrawals()).items, isNotEmpty);
    });
  });

  group('errors', () {
    test(
      'validation envelope maps to ApiException with code + field details',
      () async {
        final a = ScriptedAdapter(
          (_) => jsonResponse(fx('error_validation'), 400),
        );
        await expectLater(
          DioAuthRepository(newDio(a)).login(email: 'x', password: 'y'),
          throwsA(
            isA<ApiException>()
                .having((e) => e.code, 'code', ApiErrorCodes.validation)
                .having(
                  (e) => (e.details as Map)['fields'],
                  'details.fields',
                  isA<Map>(),
                ),
          ),
        );
      },
    );

    test(
      'publish blocked by the contribution rule keeps code, message and details',
      () {
        final e =
            ApiException.tryParseBody(
              fx('error_contribution_required'),
              statusCode: 403,
            )!;
        expect(e.code, ApiErrorCodes.contributionRequired);
        expect(e.message, contains('free drawing'));
        expect((e.details! as Map)['freeNeeded'], greaterThanOrEqualTo(1));
      },
    );

    test('conflict and unauthorized envelopes keep their codes', () {
      expect(
        ApiException.tryParseBody(fx('error_conflict'), statusCode: 409)!.code,
        ApiErrorCodes.conflict,
      );
      expect(
        ApiException.tryParseBody(
          fx('error_unauthorized'),
          statusCode: 401,
        )!.code,
        ApiErrorCodes.unauthorized,
      );
    });
  });
}
