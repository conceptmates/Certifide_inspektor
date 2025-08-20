// lib/models/dropdown_option.dart
import 'package:flutter/material.dart';

class DropdownOption<T> {
  final T value;
  final String label;
  final Color color;

  const DropdownOption({
    required this.value,
    required this.label,
    required this.color,
  });
}
