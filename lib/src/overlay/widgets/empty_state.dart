import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white24, size: 32),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.white38)),
          ],
        ),
      );
}

class PanelSearchBar extends StatelessWidget {
  const PanelSearchBar(
      {super.key, required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
        onChanged: onChanged,
        style: const TextStyle(fontSize: 12, color: Colors.white70),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(fontSize: 11, color: Colors.white24),
          prefixIcon: const Icon(Icons.search, color: Colors.white24, size: 16),
          isDense: true,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
