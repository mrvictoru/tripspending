import 'package:flutter/material.dart';
import 'package:tripspending/models/trip.dart';
import 'package:tripspending/services/database_service.dart';
import 'package:intl/intl.dart';

/// Card widget displaying trip summary
class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        if (trip.description != null)
                          Text(
                            trip.description!,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        onDelete();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Date range
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
                      _formatDateRange(trip.startDate, trip.endDate),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              const SizedBox(height: 12),

              // Stats row
              FutureBuilder<Map<String, dynamic>>(
                future: _getTripStats(trip.id!),
                builder: (context, snapshot) {
                  final stats = snapshot.data ?? {'spent': 0.0, 'count': 0};
                  final spent = stats['spent'] as double;
                  final count = stats['count'] as int;

                  return Row(
                    children: [
                      // Receipts count
                      _StatBadge(
                        icon: Icons.receipt_long,
                        value: count.toString(),
                        label: 'receipts',
                      ),
                      const SizedBox(width: 16),

                      // Total spent
                      _StatBadge(
                        icon: Icons.attach_money,
                        value: '${trip.currency} ${spent.toStringAsFixed(0)}',
                        label: 'spent',
                      ),

                      const Spacer(),

                      // Budget progress if set
                      if (trip.budget != null) ...[
                        _BudgetProgress(
                          spent: spent,
                          budget: trip.budget!,
                          currency: trip.currency,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final dateFormat = DateFormat('MMM d, yyyy');
    if (start != null && end != null) {
      return '${dateFormat.format(start)} - ${dateFormat.format(end)}';
    } else if (start != null) {
      return 'From ${dateFormat.format(start)}';
    } else if (end != null) {
      return 'Until ${dateFormat.format(end)}';
    }
    return '';
  }

  Future<Map<String, dynamic>> _getTripStats(int tripId) async {
    final db = DatabaseService.instance;
    final spent = await db.getTotalSpentForTrip(tripId);
    final count = await db.getReceiptCountForTrip(tripId);
    return {'spent': spent, 'count': count};
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _BudgetProgress extends StatelessWidget {
  final double spent;
  final double budget;
  final String currency;

  const _BudgetProgress({
    required this.spent,
    required this.budget,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (spent / budget).clamp(0.0, 1.0);
    final isOver = spent > budget;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$currency ${budget.toStringAsFixed(0)} budget',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              color: isOver
                  ? Colors.red
                  : progress > 0.8
                      ? Colors.orange
                      : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
