import 'package:flutter/material.dart';

@immutable
class CustomColors extends ThemeExtension<CustomColors> {
  const CustomColors({
    required this.safeStateGreen,
    required this.warningAmber,
    required this.statusBlue,
    required this.emergencyRed,
    required this.textSecondary,
    required this.lightTextSecondary,
    required this.backgroundGray,
    required this.borderGray,
  });

  final Color safeStateGreen;
  final Color warningAmber;
  final Color statusBlue;
  final Color emergencyRed;
  final Color textSecondary;
  final Color lightTextSecondary;
  final Color backgroundGray;
  final Color borderGray;

  @override
  CustomColors copyWith({
    Color? safeStateGreen,
    Color? warningAmber,
    Color? statusBlue,
    Color? emergencyRed,
    Color? textSecondary,
    Color? lightTextSecondary,
    Color? backgroundGray,
    Color? borderGray,
  }) {
    return CustomColors(
      safeStateGreen: safeStateGreen ?? this.safeStateGreen,
      warningAmber: warningAmber ?? this.warningAmber,
      statusBlue: statusBlue ?? this.statusBlue,
      emergencyRed: emergencyRed ?? this.emergencyRed,
      textSecondary: textSecondary ?? this.textSecondary,
      lightTextSecondary: lightTextSecondary ?? this.lightTextSecondary,
      backgroundGray: backgroundGray ?? this.backgroundGray,
      borderGray: borderGray ?? this.borderGray,
    );
  }

  @override
  CustomColors lerp(ThemeExtension<CustomColors>? other, double t) {
    if (other is! CustomColors) {
      return this;
    }
    return CustomColors(
      safeStateGreen: Color.lerp(safeStateGreen, other.safeStateGreen, t)!,
      warningAmber: Color.lerp(warningAmber, other.warningAmber, t)!,
      statusBlue: Color.lerp(statusBlue, other.statusBlue, t)!,
      emergencyRed: Color.lerp(emergencyRed, other.emergencyRed, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      lightTextSecondary:
          Color.lerp(lightTextSecondary, other.lightTextSecondary, t)!,
      backgroundGray: Color.lerp(backgroundGray, other.backgroundGray, t)!,
      borderGray: Color.lerp(borderGray, other.borderGray, t)!,
    );
  }
}
