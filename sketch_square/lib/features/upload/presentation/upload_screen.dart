import 'package:flutter/material.dart';

import '../../../core/widgets/placeholder_screen.dart';

class UploadScreen extends StatelessWidget {
  const UploadScreen({super.key});

  @override
  Widget build(BuildContext context) => const PlaceholderScreen(
    title: 'Upload',
    icon: Icons.add_box_outlined,
    message: 'Publish your drawings to the marketplace.',
  );
}
