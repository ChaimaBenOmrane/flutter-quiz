// widgets/qr_code_widget.dart
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeWidget extends StatelessWidget {
  final String sessionId;

  QRCodeWidget({required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return QrImageView(
      data: sessionId,
      version: QrVersions.auto,
      size: 200.0,
    );
  }
}
