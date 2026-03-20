import 'package:flutter/material.dart';

import '../../core/flags/flag_config.dart';
import '../../devkit.dart';

class FlagsPanel extends StatelessWidget {
  const FlagsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final configs = BlackBox.instance.flagStore.configs;

    if (configs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, color: Colors.white24, size: 32),
            SizedBox(height: 8),
            Text('No flags registered',
                style: TextStyle(fontSize: 12, color: Colors.white38)),
            SizedBox(height: 4),
            Text(
              'Pass a flagAdapter to BlackBox.setup()',
              style: TextStyle(fontSize: 10, color: Colors.white24),
            ),
          ],
        ),
      );
    }

    // Group by FlagConfig.group
    final groups = <String, List<MapEntry<String, FlagConfig>>>{};
    for (final entry in configs.entries) {
      final group = entry.value.group ?? 'General';
      groups.putIfAbsent(group, () => []).add(entry);
    }

    return StreamBuilder<Map<String, dynamic>>(
      stream: BlackBox.instance.flagStore.stream,
      initialData: BlackBox.instance.flagStore.allCurrentValues,
      builder: (context, snapshot) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 16),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.refresh, size: 12),
                label: const Text('Reset all', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white38, padding: EdgeInsets.zero),
                onPressed: () => BlackBox.instance.flagStore.resetAll(),
              ),
            ),
            for (final group in groups.entries) ...[
              _GroupHeader(group.key),
              ...group.value.map(
                (e) => _FlagTile(
                  flagKey: e.key,
                  config: e.value,
                  currentValue: snapshot.data?[e.key] ?? e.value.defaultValue,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GroupHeader extends StatelessWidget {
  const _GroupHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
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
}

class _FlagTile extends StatelessWidget {
  const _FlagTile({
    required this.flagKey,
    required this.config,
    required this.currentValue,
  });

  final String flagKey;
  final FlagConfig config;
  final dynamic currentValue;

  bool get _isOverridden => currentValue != config.defaultValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isOverridden
              ? const Color(0xFF6C63FF).withValues(alpha: 0.4)
              : Colors.white10,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(flagKey,
                        style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white70,
                            fontFamily: 'monospace')),
                    if (_isOverridden) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('OVERRIDE',
                            style: TextStyle(
                                fontSize: 7,
                                color: Color(0xFF6C63FF),
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                if (config.description != null)
                  Text(config.description!,
                      style:
                          const TextStyle(fontSize: 9, color: Colors.white38)),
                Text(
                  'default: ${config.defaultValue}',
                  style: const TextStyle(
                      fontSize: 9,
                      color: Colors.white24,
                      fontFamily: 'monospace'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _FlagControl(
            flagKey: flagKey,
            config: config,
            currentValue: currentValue,
          ),
        ],
      ),
    );
  }
}

class _FlagControl extends StatelessWidget {
  const _FlagControl({
    required this.flagKey,
    required this.config,
    required this.currentValue,
  });

  final String flagKey;
  final FlagConfig config;
  final dynamic currentValue;

  @override
  Widget build(BuildContext context) {
    return switch (config.type) {
      FlagType.boolean => Switch(
          value: currentValue as bool,
          onChanged: (v) => BlackBox.instance.flagStore.override(flagKey, v),
          activeThumbColor: const Color(0xFF6C63FF),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      FlagType.string => SizedBox(
          width: 110,
          child: TextField(
            controller: TextEditingController(text: currentValue.toString()),
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) =>
                BlackBox.instance.flagStore.override(flagKey, v),
          ),
        ),
      FlagType.integer => SizedBox(
          width: 80,
          child: TextField(
            controller: TextEditingController(text: currentValue.toString()),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => BlackBox.instance.flagStore
                .override(flagKey, int.tryParse(v) ?? currentValue),
          ),
        ),
      FlagType.decimal => SizedBox(
          width: 80,
          child: TextField(
            controller: TextEditingController(text: currentValue.toString()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(fontSize: 11, color: Colors.white70),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              border: OutlineInputBorder(),
            ),
            onSubmitted: (v) => BlackBox.instance.flagStore
                .override(flagKey, double.tryParse(v) ?? currentValue),
          ),
        ),
    };
  }
}
