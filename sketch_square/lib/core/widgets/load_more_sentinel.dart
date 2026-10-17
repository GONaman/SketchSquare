import 'package:flutter/material.dart';

/// Last item of a paged list: asks for the next page once it is built (i.e.
/// scrolled into view) and renders the spinner / retry state. Key it by the
/// item count so each loaded page re-arms it.
class LoadMoreSentinel extends StatefulWidget {
  const LoadMoreSentinel({
    super.key,
    required this.onLoadMore,
    required this.loading,
    this.errorMessage,
    this.onRetry,
  });

  final VoidCallback onLoadMore;
  final bool loading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<LoadMoreSentinel> createState() => _LoadMoreSentinelState();
}

class _LoadMoreSentinelState extends State<LoadMoreSentinel> {
  @override
  void initState() {
    super.initState();
    if (!widget.loading && widget.errorMessage == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return TextButton(
        onPressed: widget.onRetry,
        child: Text('${widget.errorMessage} Tap to retry'),
      );
    }
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}
