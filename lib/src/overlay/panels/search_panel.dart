import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../blackbox.dart';
import '../widgets/blackbox_colors.dart';
import '../widgets/empty_state.dart';

/// A unified search panel that searches across Network, Logs, Storage,
/// Socket, and Crash stores simultaneously.
class SearchPanel extends StatefulWidget {
  const SearchPanel({super.key});

  @override
  State<SearchPanel> createState() => _SearchPanelState();
}

class _SearchPanelState extends State<SearchPanel> {
  String _query = '';
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchResult> _search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    final results = <_SearchResult>[];

    // ── Search Network ──
    for (final entry in BlackBox.instance.networkStore.entries) {
      final req = entry.request;
      final res = entry.response;

      final urlMatch = req.url.toLowerCase().contains(q);
      final methodMatch = req.method.toLowerCase().contains(q);
      final bodyMatch = req.body?.toString().toLowerCase().contains(q) == true;
      final resBodyMatch =
          res?.body?.toString().toLowerCase().contains(q) == true;
      final headerMatch = req.headers.toString().toLowerCase().contains(q);

      if (urlMatch || methodMatch || bodyMatch || resBodyMatch || headerMatch) {
        final matchIn = <String>[];
        if (urlMatch) matchIn.add('URL');
        if (methodMatch) matchIn.add('method');
        if (bodyMatch) matchIn.add('request body');
        if (resBodyMatch) matchIn.add('response body');
        if (headerMatch) matchIn.add('headers');

        results.add(_SearchResult(
          source: 'Network',
          icon: Icons.wifi,
          color: Colors.blue,
          title: '${req.method} ${_shortenUrl(req.url)}',
          subtitle: 'Matched in: ${matchIn.join(", ")}',
          detail:
              '${res?.statusCode ?? "Pending"} • ${res?.durationMs ?? "–"}ms',
          timestamp: req.timestamp,
          copyText: req.url,
        ));
      }
    }

    // ── Search Logs ──
    for (final entry in BlackBox.instance.logStore.entries) {
      final msgMatch = entry.message.toLowerCase().contains(q);
      final tagMatch = entry.tag?.toLowerCase().contains(q) == true;
      final dataMatch =
          entry.data?.toString().toLowerCase().contains(q) == true;

      if (msgMatch || tagMatch || dataMatch) {
        results.add(_SearchResult(
          source: 'Logs',
          icon: Icons.article_outlined,
          color: BlackBoxColors.warning,
          title: entry.message.length > 80
              ? '${entry.message.substring(0, 80)}…'
              : entry.message,
          subtitle: entry.tag != null ? 'Tag: ${entry.tag}' : entry.level.label,
          detail: entry.level.label.toUpperCase(),
          timestamp: entry.timestamp,
          copyText: entry.message,
        ));
      }
    }

    // ── Search Crashes ──
    for (final entry in BlackBox.instance.crashStore.entries) {
      final msgMatch = entry.message.toLowerCase().contains(q);
      final libMatch = entry.library?.toLowerCase().contains(q) == true;
      final stackMatch =
          entry.stackTrace?.toString().toLowerCase().contains(q) == true;

      if (msgMatch || libMatch || stackMatch) {
        results.add(_SearchResult(
          source: 'Crash',
          icon: Icons.bug_report_outlined,
          color: BlackBoxColors.error,
          title: entry.message.length > 80
              ? '${entry.message.substring(0, 80)}…'
              : entry.message,
          subtitle: entry.library ?? 'Unknown',
          detail: 'CRASH',
          timestamp: entry.timestamp,
          copyText: entry.message,
        ));
      }
    }

    // ── Search Socket Events ──
    for (final entry in BlackBox.instance.socketStore.events) {
      final nameMatch = entry.eventName.toLowerCase().contains(q);
      final dataMatch =
          entry.data?.toString().toLowerCase().contains(q) == true;

      if (nameMatch || dataMatch) {
        results.add(_SearchResult(
          source: 'Socket',
          icon: Icons.power,
          color: Colors.purple,
          title: entry.eventName,
          subtitle: entry.direction.name,
          detail: entry.data?.toString().length.toString() ?? '',
          timestamp: entry.timestamp,
          copyText:
              '${entry.eventName}: ${entry.data?.toString() ?? "no data"}',
        ));
      }
    }

    // Sort by timestamp (newest first)
    results.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return results;
  }

  String _shortenUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      return path.isEmpty ? '/' : path;
    } catch (_) {
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _search(_query);

    return Column(
      children: [
        // ── Search bar ──
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _query.isNotEmpty
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.5)
                    : Colors.white10,
              ),
            ),
            child: TextField(
              controller: _controller,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                  fontSize: 12, color: Colors.white70, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'Search across Network, Logs, Crashes, Sockets…',
                hintStyle: const TextStyle(fontSize: 11, color: Colors.white24),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.white24, size: 16),
                suffixIcon: _query.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                        child: const Icon(Icons.close,
                            color: Colors.white24, size: 14),
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),

        // ── Results ──
        if (_query.isEmpty)
          const Expanded(
            child: EmptyState(
              icon: Icons.search,
              label:
                  'Search across all panels\nNetwork • Logs • Crashes • Socket',
            ),
          )
        else if (results.isEmpty)
          Expanded(
            child: EmptyState(
              icon: Icons.search_off,
              label: 'No results for "$_query"',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${results.length} result${results.length == 1 ? '' : 's'}',
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (ctx, i) => _SearchResultTile(result: results[i]),
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SearchResult {
  const _SearchResult({
    required this.source,
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.timestamp,
    required this.copyText,
  });

  final String source;
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String detail;
  final DateTime timestamp;
  final String copyText;
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.result});
  final _SearchResult result;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: result.copyText));
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(
            content: Text('Copied ${result.source} entry',
                style: const TextStyle(fontSize: 12)),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF2A2A3E),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Source badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: result.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(result.icon, size: 10, color: result.color),
                      const SizedBox(width: 3),
                      Text(
                        result.source,
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: result.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        style: const TextStyle(
                            fontSize: 11, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        result.subtitle,
                        style:
                            const TextStyle(fontSize: 9, color: Colors.white30),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  result.detail,
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: result.color),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
        ],
      ),
    );
  }
}
