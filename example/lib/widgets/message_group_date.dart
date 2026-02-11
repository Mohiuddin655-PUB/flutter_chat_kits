import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChattingMessageGroupDate extends StatelessWidget {
  final DateTime date;

  const ChattingMessageGroupDate({super.key, required this.date});

  DateTime get normalized {
    return DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
      date.second,
    );
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final md = DateTime(date.year, date.month, date.day);
    if (md == today) {
      return 'Today';
    } else if (md == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d, yyyy').format(date).toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      key: ValueKey('date_${normalized.second}'),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          _dateLabel(date),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
