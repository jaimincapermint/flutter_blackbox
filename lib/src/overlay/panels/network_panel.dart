import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/network/network_store.dart';
import '../../core/network/network_response.dart';
import '../../core/network/network_throttle.dart';
import '../../devkit.dart';
import '../widgets/devkit_colors.dart';
import '../widgets/empty_state.dart';

class NetworkPanel extends StatefulWidget {
  const NetworkPanel({super.key});

  @override
  State<NetworkPanel> createState() => _NetworkPanelState();
}

class _NetworkPanelState extends State<NetworkPanel> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
          child: Row(
            children: [
              Expanded(
                child: PanelSearchBar(
                  hint: 'Filter by URL…',
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    backgroundColor: const Color(0xff2A2A2A),
                    builder: (ctx) => const _ThrottleSettingsSheet(),
                  );
                },
                child: const Icon(Icons.speed, color: Colors.white38, size: 18),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => BlackBox.instance.networkStore.clear(),
                child: const Icon(Icons.delete_outline,
                    color: Colors.white38, size: 18),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<NetworkEntry>>(
            stream: BlackBox.instance.networkStore.stream,
            initialData: BlackBox.instance.networkStore.entries,
            builder: (context, snapshot) {
              var entries = snapshot.data ?? [];
              if (_query.isNotEmpty) {
                entries = entries
                    .where((e) => e.request.url
                        .toLowerCase()
                        .contains(_query.toLowerCase()))
                    .toList();
              }
              if (entries.isEmpty) {
                return const EmptyState(
                    icon: Icons.wifi_off, label: 'No requests yet');
              }

              String baseUrl = '';
              try {
                baseUrl = Uri.parse(entries.last.request.url).origin;
              } catch (_) {}

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (baseUrl.isNotEmpty)
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 12, bottom: 8),
                      child: Text(
                        'Base URL: $baseUrl',
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      reverse: false,
                      itemCount: entries.length,
                      itemBuilder: (ctx, i) =>
                          _NetworkTile(entry: entries[entries.length - 1 - i]),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ThrottleSettingsSheet extends StatefulWidget {
  const _ThrottleSettingsSheet();
  @override
  State<_ThrottleSettingsSheet> createState() => _ThrottleSettingsSheetState();
}

class _ThrottleSettingsSheetState extends State<_ThrottleSettingsSheet> {
  @override
  Widget build(BuildContext context) {
    final throttle = NetworkThrottle.instance;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Network Throttle (Mocks Only)',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Throttle',
                  style: TextStyle(color: Colors.white, fontSize: 13)),
              value: throttle.enabled,
              onChanged: (v) => setState(() => throttle.enabled = v),
              activeTrackColor: BlackBoxColors.success.withValues(alpha: 0.5),
              activeThumbColor: BlackBoxColors.success,
              contentPadding: EdgeInsets.zero,
            ),
            if (throttle.enabled) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Delay (ms)',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: throttle.delayMs.toDouble(),
                      min: 0,
                      max: 5000,
                      divisions: 50,
                      activeColor: BlackBoxColors.success,
                      inactiveColor: Colors.white12,
                      label: '${throttle.delayMs} ms',
                      onChanged: (v) =>
                          setState(() => throttle.delayMs = v.toInt()),
                    ),
                  ),
                  Text('${throttle.delayMs} ms',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ]
          ],
        ),
      ),
    );
  }
}

class _NetworkTile extends StatefulWidget {
  const _NetworkTile({required this.entry});
  final NetworkEntry entry;

  @override
  State<_NetworkTile> createState() => _NetworkTileState();
}

class _NetworkTileState extends State<_NetworkTile> {
  bool _expanded = false;

  Color get _statusColor {
    final code = widget.entry.response?.statusCode ?? 0;
    if (code == 0) return Colors.white38;
    if (code < 300) return BlackBoxColors.success;
    if (code < 500) return BlackBoxColors.warning;
    return BlackBoxColors.error;
  }

  @override
  Widget build(BuildContext context) {
    final req = widget.entry.request;
    final res = widget.entry.response;

    String endpoint = req.url;
    try {
      final uri = Uri.parse(req.url);
      endpoint = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      if (endpoint.isEmpty) endpoint = '/';
    } catch (_) {}

    return InkWell(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                _MethodBadge(method: req.method),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    endpoint,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (res != null) ...[
                  const SizedBox(width: 8),
                  if (res.failureType != NetworkFailureType.none) ...[
                    const SizedBox(height: 12),
                    const Text('Network Failure',
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.white38,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      res.failureType.name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11, color: Colors.redAccent),
                    ),
                  ] else ...[
                    Text(
                      '${res.statusCode}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _statusColor),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${res.durationMs}ms',
                      style:
                          const TextStyle(fontSize: 10, color: Colors.white38),
                    ),
                  ],
                ] else
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(color: Colors.white38),
                  ),
                // remove isMocked display because it was completely stripped
                Icon(
                  _expanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.white24,
                  size: 16,
                ),
              ],
            ),
          ),
          if (_expanded) _NetworkDetail(entry: widget.entry),
          const Divider(color: Colors.white10, height: 1),
        ],
      ),
    );
  }
}

class _NetworkDetail extends StatelessWidget {
  const _NetworkDetail({required this.entry});
  final NetworkEntry entry;

  @override
  Widget build(BuildContext context) {
    final req = entry.request;
    final res = entry.response;

    return Container(
      color: Colors.white.withValues(alpha: 0.03),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (req.headers.isNotEmpty)
            _Section(
                title: 'Request Headers',
                content: _truncate(_formatJson(req.headers))),
          if (req.body != null)
            _Section(
                title: 'Request Body',
                content: _truncate(_formatJson(req.body))),
          if (res != null) ...[
            _Section(
                title: 'Response status code:',
                content: res.statusCode.toString()),
            _Section(
                title: 'Response message:',
                content: res.failureType != NetworkFailureType.none
                    ? _truncate(res.failureType.name)
                    : 'Success'),
            if (res.body != null)
              _Section(
                  title: 'Response Body',
                  content: _truncate(_formatJson(res.body))),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.copy, size: 12),
                  label: const Text('Copy URL', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      padding: EdgeInsets.zero),
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: req.url)),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.copy_all, size: 12),
                  label: const Text('Copy Full Response',
                      style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.white38,
                      padding: EdgeInsets.zero),
                  onPressed: () {
                    final fullData = '''Request URL: ${req.url}
Request Headers:
${_formatJson(req.headers)}

Request Body:
${req.body != null ? _formatJson(req.body) : 'None'}

Response status code: ${res?.statusCode ?? 'None'}
Response message: ${res != null && res.failureType != NetworkFailureType.none ? res.failureType.name : 'Success'}
Response Body:
${res?.body != null ? _formatJson(res!.body) : 'None'}''';
                    Clipboard.setData(ClipboardData(text: fullData));
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJson(dynamic data) {
    if (data == null) return '';
    try {
      if (data is String) {
        final decoded = jsonDecode(data);
        return const JsonEncoder.withIndent('  ').convert(decoded);
      }
      return const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      return data.toString();
    }
  }

  String _truncate(String str, [int maxLen = 3000]) {
    if (str.length <= maxLen) return str;
    return '${str.substring(0, maxLen)}...\n\n[TRUNCATED to preserve performance]';
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 9,
                  color: Colors.white38,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .5)),
          const SizedBox(height: 2),
          Text(content,
              style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white60,
                  fontFamily: 'monospace',
                  height: 1.4)),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  const _MethodBadge({required this.method});
  final String method;

  Color get _color => switch (method.toUpperCase()) {
        'GET' => Colors.green,
        'POST' => Colors.blue,
        'PUT' || 'PATCH' => Colors.orange,
        'DELETE' => Colors.red,
        _ => Colors.grey,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        method.toUpperCase(),
        style:
            TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _color),
      ),
    );
  }
}
