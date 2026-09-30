import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showLegalDocumentDialog(
  BuildContext context, {
  required String title,
  required String assetPath,
}) async {
  final text = await rootBundle.loadString(assetPath);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(child: SelectableText(text)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}
