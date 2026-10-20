import 'package:flutter/material.dart';
import '../../domain/models/dday_entity.dart';

class DDayCountdownWidget extends StatelessWidget {
  final DDayEntity dday;
  final double? syllabusProgress;
  final DateTime? referenceDate;
  final VoidCallback? onTap;

  const DDayCountdownWidget({
    super.key,
    required this.dday,
    this.syllabusProgress,
    this.referenceDate,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = dday.daysRemaining(referenceDate: referenceDate);
    final formattedBadge = dday.formatDDay(referenceDate: referenceDate);

    Color badgeColor;
    if (days == 0) {
      badgeColor = Colors.redAccent;
    } else if (days > 0) {
      badgeColor = days <= 7 ? Colors.orange : theme.colorScheme.primary;
    } else {
      badgeColor = Colors.grey;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dday.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      formattedBadge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Target: ${dday.targetDate.year}-${dday.targetDate.month.toString().padLeft(2, '0')}-${dday.targetDate.day.toString().padLeft(2, '0')}',
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              if (syllabusProgress != null) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Syllabus Coverage',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${syllabusProgress!.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (syllabusProgress! / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      syllabusProgress! >= 100.0 ? Colors.green : theme.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
