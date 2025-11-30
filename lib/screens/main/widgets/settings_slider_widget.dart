import 'package:flutter/material.dart';

class SettingsSliderWidget extends StatelessWidget {
  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String? label;

  const SettingsSliderWidget({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            label: label ?? value.toStringAsFixed(1),
            onChanged: onChanged,
          ),
          Text(
            '${value.toStringAsFixed(1)} ${_getUnit()}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  String _getUnit() {
    if (title.toLowerCase().contains('volume')) return '';
    if (title.toLowerCase().contains('sensitivity')) return '';
    if (title.toLowerCase().contains('threshold')) return '';
    if (title.toLowerCase().contains('duration')) return 'seconds';
    if (title.toLowerCase().contains('days')) return 'days';
    return '';
  }
}
