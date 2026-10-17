/// Cursor page: `{ "items": [...], "nextCursor": "<opaque>"|null }`.
/// Request side: `?cursor=<opaque>&limit=20` (default 20, max 50).
class CursorPage<T> {
  const CursorPage({required this.items, this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  factory CursorPage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) itemFromJson,
  ) {
    final raw = json['items'] as List<dynamic>? ?? const [];
    return CursorPage(
      items: raw
          .map((e) => itemFromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      nextCursor: json['nextCursor'] as String?,
    );
  }

  static const defaultLimit = 20;
  static const maxLimit = 50;
}
