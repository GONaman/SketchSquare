/// `GET /me/contribution-status` (docs/API_CONTRACT.md, Phase 8.3): whether the
/// architect may publish another paid drawing under the contribution rule.
class ContributionStatus {
  const ContributionStatus({
    this.freePublished = 0,
    this.paidPublished = 0,
    this.paidPending = 0,
    this.freePerPaid = 1,
    this.freeNeeded = 0,
    this.canPublishPaid = true,
    this.guidance = '',
  });

  factory ContributionStatus.fromJson(Map<String, dynamic> json) =>
      ContributionStatus(
        freePublished: (json['freePublished'] as num?)?.toInt() ?? 0,
        paidPublished: (json['paidPublished'] as num?)?.toInt() ?? 0,
        paidPending: (json['paidPending'] as num?)?.toInt() ?? 0,
        freePerPaid: (json['freePerPaid'] as num?)?.toInt() ?? 1,
        freeNeeded: (json['freeNeeded'] as num?)?.toInt() ?? 0,
        canPublishPaid: json['canPublishPaid'] as bool? ?? true,
        guidance: json['guidance'] as String? ?? '',
      );

  final int freePublished;
  final int paidPublished;
  final int paidPending;
  final int freePerPaid;
  final int freeNeeded;
  final bool canPublishPaid;
  final String guidance;

  /// The rule is switched off server-side when `freePerPaid` is 0.
  bool get ruleActive => freePerPaid > 0;

  /// Always explains the rule, even when the server sent no guidance.
  String get explanation {
    if (guidance.isNotEmpty) return guidance;
    if (!ruleActive) return '';
    final free = freePerPaid == 1 ? 'free drawing' : 'free drawings';
    return 'Publish $freePerPaid $free for every paid drawing you list. '
        'Your first paid drawing is always allowed.';
  }

  /// Friendly copy for the "can't publish paid" state.
  String get blockedMessage {
    final n = freeNeeded < 1 ? 1 : freeNeeded;
    final free = n == 1 ? 'free drawing' : 'free drawings';
    return 'Publish $n more $free to unlock another paid drawing, '
        'or make this one free.';
  }
}
