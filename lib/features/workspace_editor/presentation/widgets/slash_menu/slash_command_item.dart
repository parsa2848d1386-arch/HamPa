import 'package:flutter/material.dart';
import '../../../domain/models/block_type.dart';

class SlashCommandItem {
  final BlockType type;
  final String title;
  final String subtitle;
  final IconData icon;

  const SlashCommandItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
