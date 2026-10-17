import '../../drawings/domain/drawing_summary.dart';
import '../../drawings/domain/sheet.dart';

enum PurchaseKind {
  paid,
  free;

  static PurchaseKind fromApi(String? value) =>
      value == 'FREE' ? PurchaseKind.free : PurchaseKind.paid;
}

/// One row of `GET /me/purchases`:
/// `{ kind, purchasedAt, pricePaise, purchaseId|null, drawing: DrawingSummary & {sheets} }`.
class PurchaseItem {
  const PurchaseItem({
    required this.kind,
    required this.purchasedAt,
    required this.pricePaise,
    required this.drawing,
    required this.sheets,
    this.purchaseId,
  });

  factory PurchaseItem.fromJson(Map<String, dynamic> json) {
    final drawing = json['drawing'] as Map<String, dynamic>;
    return PurchaseItem(
      kind: PurchaseKind.fromApi(json['kind'] as String?),
      purchasedAt: DateTime.parse(json['purchasedAt'] as String),
      pricePaise: (json['pricePaise'] as num?)?.toInt() ?? 0,
      purchaseId: json['purchaseId'] as String?,
      drawing: DrawingSummary.fromJson(drawing),
      sheets: [
        for (final s in drawing['sheets'] as List<dynamic>? ?? const [])
          Sheet.fromJson(s as Map<String, dynamic>),
      ],
    );
  }

  final PurchaseKind kind;
  final DateTime purchasedAt;
  final int pricePaise;
  final String? purchaseId;
  final DrawingSummary drawing;
  final List<Sheet> sheets;

  bool get isFree => kind == PurchaseKind.free;

  /// A drawing can appear once per library; the id is the paging identity.
  String get key => drawing.id;
}

/// `GET /drawings/:id/download` response.
class DownloadLink {
  const DownloadLink({
    required this.url,
    required this.fileName,
    this.expiresInSeconds = 300,
  });

  factory DownloadLink.fromJson(Map<String, dynamic> json) => DownloadLink(
    url: json['url'] as String,
    fileName: json['fileName'] as String,
    expiresInSeconds: (json['expiresInSeconds'] as num?)?.toInt() ?? 300,
  );

  final String url;
  final String fileName;
  final int expiresInSeconds;
}
