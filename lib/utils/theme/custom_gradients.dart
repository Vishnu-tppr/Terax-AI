import 'package:flutter/material.dart';

@immutable
class CustomGradients extends ThemeExtension<CustomGradients> {
  const CustomGradients({
    required this.primaryGradient,
    required this.emergencyGradient,
  });

  final LinearGradient primaryGradient;
  final LinearGradient emergencyGradient;

  @override
  CustomGradients copyWith({
    LinearGradient? primaryGradient,
    LinearGradient? emergencyGradient,
  }) {
    return CustomGradients(
      primaryGradient: primaryGradient ?? this.primaryGradient,
      emergencyGradient: emergencyGradient ?? this.emergencyGradient,
    );
  }

  @override
  CustomGradients lerp(ThemeExtension<CustomGradients>? other, double t) {
    if (other is! CustomGradients) {
      return this;
    }
    return CustomGradients(
      primaryGradient: LinearGradient(
        colors: [
          Color.lerp(
              primaryGradient.colors[0], other.primaryGradient.colors[0], t)!,
          Color.lerp(
              primaryGradient.colors[1], other.primaryGradient.colors[1], t)!,
        ],
        begin: primaryGradient.begin,
        end: primaryGradient.end,
      ),
      emergencyGradient: LinearGradient(
        colors: [
          Color.lerp(emergencyGradient.colors[0],
              other.emergencyGradient.colors[0], t)!,
          Color.lerp(emergencyGradient.colors[1],
              other.emergencyGradient.colors[1], t)!,
        ],
        begin: emergencyGradient.begin,
        end: emergencyGradient.end,
      ),
    );
  }
}
