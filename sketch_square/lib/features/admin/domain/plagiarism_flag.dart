enum PlagiarismFlagStatus {
  pending('PENDING'),
  approved('APPROVED'),
  rejected('REJECTED');

  const PlagiarismFlagStatus(this.wire);
  final String wire;

  static PlagiarismFlagStatus parse(Object? value) =>
      values.firstWhere((s) => s.wire == value, orElse: () => pending);
}

/// The slice of `ReviewDrawing` (docs/API_CONTRACT.md) an admin compares:
/// preview data only, never original files.
class ReviewDrawing {
  const ReviewDrawing({
    required this.id,
    required this.title,
    this.description = '',
    this.city = '',
    this.plotLengthFt = 0,
    this.plotBreadthFt = 0,
    this.pricePaise = 0,
    this.isFree = false,
    this.architectName = '',
    this.architectCity = '',
    this.previewUrls = const [],
  });

  factory ReviewDrawing.fromJson(Map<String, dynamic> json) {
    final architect = json['architect'];
    final sheets = json['sheets'];
    return ReviewDrawing(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      city: json['city'] as String? ?? '',
      plotLengthFt: (json['plotLengthFt'] as num?)?.toDouble() ?? 0,
      plotBreadthFt: (json['plotBreadthFt'] as num?)?.toDouble() ?? 0,
      pricePaise: (json['pricePaise'] as num?)?.toInt() ?? 0,
      isFree: json['isFree'] as bool? ?? false,
      architectName:
          architect is Map ? architect['fullName'] as String? ?? '' : '',
      architectCity: architect is Map ? architect['city'] as String? ?? '' : '',
      previewUrls: [
        if (sheets is List)
          for (final s in sheets)
            if (s is Map && s['previewUrl'] is String)
              s['previewUrl'] as String,
      ],
    );
  }

  final String id;
  final String title;
  final String description;
  final String city;
  final double plotLengthFt;
  final double plotBreadthFt;
  final int pricePaise;
  final bool isFree;
  final String architectName;
  final String architectCity;
  final List<String> previewUrls;
}

/// `PlagiarismFlagItem` from `GET /admin/plagiarism-flags`.
class PlagiarismFlag {
  const PlagiarismFlag({
    required this.id,
    required this.status,
    required this.hammingDistance,
    required this.createdAt,
    required this.drawing,
    required this.matchedDrawing,
    this.reviewNote,
    this.flaggedPreviewUrl,
    this.matchedPreviewUrl,
  });

  factory PlagiarismFlag.fromJson(Map<String, dynamic> json) {
    String? previewOf(Object? sheet) =>
        sheet is Map ? sheet['previewUrl'] as String? : null;
    final drawing = ReviewDrawing.fromJson(
      json['drawing'] as Map<String, dynamic>,
    );
    final matched = ReviewDrawing.fromJson(
      json['matchedDrawing'] as Map<String, dynamic>,
    );
    return PlagiarismFlag(
      id: json['id'] as String,
      status: PlagiarismFlagStatus.parse(json['status']),
      hammingDistance: (json['hammingDistance'] as num?)?.toInt() ?? 0,
      reviewNote: json['reviewNote'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      drawing: drawing,
      matchedDrawing: matched,
      flaggedPreviewUrl:
          previewOf(json['flaggedSheet']) ?? _firstOrNull(drawing.previewUrls),
      matchedPreviewUrl:
          previewOf(json['matchedSheet']) ?? _firstOrNull(matched.previewUrls),
    );
  }

  final String id;
  final PlagiarismFlagStatus status;

  /// 0–64, lower = more similar.
  final int hammingDistance;
  final String? reviewNote;
  final DateTime createdAt;

  /// The uploaded drawing, held `UNDER_REVIEW`.
  final ReviewDrawing drawing;

  /// The existing drawing (another architect) it resembles.
  final ReviewDrawing matchedDrawing;
  final String? flaggedPreviewUrl;
  final String? matchedPreviewUrl;

  /// 100% = identical hashes.
  int get similarityPercent => (((64 - hammingDistance) / 64) * 100).round();
}

String? _firstOrNull(List<String> l) => l.isEmpty ? null : l.first;
