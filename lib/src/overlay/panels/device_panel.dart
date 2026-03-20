import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class DevicePanel extends StatelessWidget {
  const DevicePanel({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final rows = _buildRows(context, mq);

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
      children: [
        const _GroupHeader('Platform'),
        ...rows['platform']!.map(_InfoRow.fromEntry),
        const _GroupHeader('Screen'),
        ...rows['screen']!.map(_InfoRow.fromEntry),
        const _GroupHeader('App'),
        ...rows['app']!.map(_InfoRow.fromEntry),
      ],
    );
  }

  Map<String, List<MapEntry<String, String>>> _buildRows(
      BuildContext context, MediaQueryData mq) {
    final size = mq.size;
    final dpr = mq.devicePixelRatio;

    return {
      'platform': [
        MapEntry('Platform', defaultTargetPlatform.name.toUpperCase()),
        const MapEntry(
            'Mode',
            kDebugMode
                ? 'DEBUG'
                : kProfileMode
                    ? 'PROFILE'
                    : 'RELEASE'),
        if (!kIsWeb) MapEntry('OS', _osVersion()),
        const MapEntry('Web', kIsWeb ? 'Yes' : 'No'),
      ],
      'screen': [
        MapEntry('Size',
            '${size.width.toStringAsFixed(0)} × ${size.height.toStringAsFixed(0)} dp'),
        MapEntry('Physical',
            '${(size.width * dpr).toStringAsFixed(0)} × ${(size.height * dpr).toStringAsFixed(0)} px'),
        MapEntry('Pixel ratio', dpr.toStringAsFixed(2)),
        MapEntry('Text scale', mq.textScaler.scale(1).toStringAsFixed(2)),
        MapEntry('Brightness', mq.platformBrightness.name),
        MapEntry('Padding',
            'T:${mq.padding.top.toStringAsFixed(0)} B:${mq.padding.bottom.toStringAsFixed(0)}'),
      ],
      'app': [
        if (!kIsWeb)
          MapEntry('Dart version', Platform.version.split(' ').first),
        MapEntry('Debug mode', kDebugMode.toString()),
        MapEntry('Profile mode', kProfileMode.toString()),
      ],
    };
  }

  String _osVersion() {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) return 'Android';
      if (defaultTargetPlatform == TargetPlatform.iOS) return 'iOS';
      if (defaultTargetPlatform == TargetPlatform.macOS) return 'macOS';
      if (defaultTargetPlatform == TargetPlatform.windows) return 'Windows';
      if (defaultTargetPlatform == TargetPlatform.linux) return 'Linux';
      if (defaultTargetPlatform == TargetPlatform.fuchsia) return 'Fuchsia';
      return 'Unknown';
    } catch (_) {
      return 'Unknown';
    }
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(
              fontSize: 9,
              color: Colors.white24,
              fontWeight: FontWeight.w700,
              letterSpacing: .8),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  factory _InfoRow.fromEntry(MapEntry<String, String> e) =>
      _InfoRow(label: e.key, value: e.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white70,
                    fontFamily: 'monospace')),
          ),
        ],
      ),
    );
  }
}
