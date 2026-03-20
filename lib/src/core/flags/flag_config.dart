enum FlagType { boolean, string, integer, decimal }

/// Metadata about a feature flag registered with BlackBox.
class FlagConfig {
  const FlagConfig({
    required this.defaultValue,
    this.description,
    this.group,
    FlagType? type,
  }) : type = type ??
            (defaultValue is bool
                ? FlagType.boolean
                : defaultValue is int
                    ? FlagType.integer
                    : defaultValue is double
                        ? FlagType.decimal
                        : FlagType.string);

  final dynamic defaultValue;
  final String? description;

  /// Groups flags in the panel (e.g. 'Network', 'UI', 'Payments').
  final String? group;
  final FlagType type;
}
