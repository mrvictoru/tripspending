import 'package:flutter/material.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:intl/intl.dart';

/// Card showing trip statistics
class TripStatsCard extends StatelessWidget {
  final Trip trip;
  final List<Receipt> receipts;

  const TripStatsCard({
    super.key,
    required this.trip,
    required this.receipts,
  });

  @override
  Widget build(BuildContext context) {
    final totalSpent = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final remaining = (trip.budget ?? 0) - totalSpent;
    final progress = trip.budget != null ? (totalSpent / trip.budget!).clamp(0.0, 1.0) : 0.0;
    final isOverBudget = trip.budget != null && totalSpent > trip.budget!;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip date range
            if (trip.startDate != null || trip.endDate != null)
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateRange(),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            const SizedBox(height: 16),

            // Amount row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      '${trip.currency} ${totalSpent.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isOverBudget ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
                if (trip.budget != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        remaining >= 0 ? 'Remaining' : 'Over budget',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${trip.currency} ${remaining.abs().toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: remaining >= 0 ? Colors.green : Colors.red,
                            ),
                      ),
                    ],
                  ),
              ],
            ),

            // Budget progress bar
            if (trip.budget != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  color: isOverBudget
                      ? Colors.red
                      : progress > 0.8
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% of ${trip.currency} ${trip.budget!.toStringAsFixed(0)} budget',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],

            const SizedBox(height: 12),

            // Quick stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _QuickStat(
                  icon: Icons.receipt_long,
                  label: 'Receipts',
                  value: receipts.length.toString(),
                ),
                _QuickStat(
                  icon: Icons.category,
                  label: 'Categories',
                  value: _uniqueCategories().toString(),
                ),
                _QuickStat(
                  icon: Icons.trending_up,
                  label: 'Avg/Receipt',
                  value: receipts.isEmpty
                      ? '-'
                      : '${trip.currency} ${(totalSpent / receipts.length).toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange() {
    final dateFormat = DateFormat('MMM d');
    final parts = <String>[];
    
    if (trip.startDate != null) {
      parts.add(dateFormat.format(trip.startDate!));
    }
    if (trip.endDate != null) {
      parts.add(dateFormat.format(trip.endDate!));
    }
    
    return parts.join(' - ');
  }

  int _uniqueCategories() {
    return receipts.map((r) => r.category ?? 'Other').toSet().length;
  }
}

class _QuickStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
