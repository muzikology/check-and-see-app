import 'package:flutter/material.dart';

import '/beauty/banuba_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';

/// Optional helper page for validating Banuba token setup.
class PageArCloud extends StatelessWidget {
  const PageArCloud({super.key});

  static String routeName = 'PageArCloud';
  static String routePath = '/pageArCloud';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E6),
      appBar: AppBar(
        title: const Text('AR Cloud Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banuba Token Status',
              style: FlutterFlowTheme.of(context).titleMedium.override(
                    fontFamily: 'Times New Roman MT',
                    color: const Color(0xFF3B2F2F),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(height: 12),
            _statusTile('Client token', BanubaConfig.hasClientToken),
            const SizedBox(height: 8),
            _statusTile('AR Cloud token', BanubaConfig.hasArCloudToken),
            const SizedBox(height: 16),
            Text(
              'Run with tokens:\n'
              'flutter run --dart-define=BANUBA_CLIENT_TOKEN=<token> '
              '--dart-define=BANUBA_AR_CLOUD_TOKEN=<token>',
              style: FlutterFlowTheme.of(context).bodySmall.override(
                    fontFamily: 'Poppins',
                    color: const Color(0xFF5C4033),
                    letterSpacing: 0.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusTile(String label, bool ok) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE3D1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5CDAF)),
      ),
      child: Row(
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            color: ok ? const Color(0xFF5C4033) : const Color(0xFFC24664),
          ),
          const SizedBox(width: 8),
          Text('$label: ${ok ? 'configured' : 'missing'}'),
        ],
      ),
    );
  }
}
