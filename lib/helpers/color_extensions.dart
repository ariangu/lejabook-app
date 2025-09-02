import 'dart:ui';

/// Extension on Color to provide withValues method for compatibility with older Flutter versions
extension ColorExtension on Color {
  /// Creates a copy of this color with the given alpha value.
  /// This is a compatibility method for older Flutter versions that don't have withValues.
  Color withValues({double? alpha}) {
    if (alpha != null) {
      return Color.fromARGB(
        (alpha * 255).round(),
        red,
        green,
        blue,
      );
    }
    return this;
  }
} 