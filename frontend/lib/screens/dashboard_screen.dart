import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:tripspending/providers/trip_provider.dart';
import 'package:tripspending/providers/receipt_provider.dart';
import 'package:tripspending/models/category.dart';
import 'package:intl/intl.dart';

/// Dashboard screen showing spending analytics
class DashboardScreen extends StatefulWidget {
  final int tripId;

  const DashboardScreen({super.key, required this.tripId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, double> _categorySpending = {};
  Map<String, double> _dailySpending = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final tripProvider = context.read<TripProvider>();
    
    final categorySpending = await tripProvider.getCategorySpending(widget.tripId);
    final dailySpending = await tripProvider.getDailySpending(widget.tripId);

    if (mounted) {
      setState(() {
        _categorySpending = categorySpending;
        _dailySpending = dailySpending;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = context.watch<TripProvider>().selectedTrip;
    final receipts = context.watch<ReceiptProvider>().receipts;

    if (trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalSpent = receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);
    final budgetProgress = trip.budget != null ? totalSpent / trip.budget! : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spending Dashboard'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Budget Overview Card
                  _buildBudgetCard(trip, totalSpent, budgetProgress),
                  const SizedBox(height: 16),

                  // Statistics Row
                  _buildStatisticsRow(receipts.length, totalSpent, trip.currency),
                  const SizedBox(height: 24),

                  // Category Breakdown
                  if (_categorySpending.isNotEmpty) ...[
                    Text(
                      'Spending by Category',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryPieChart(trip.currency),
                    const SizedBox(height: 8),
                    _buildCategoryLegend(trip.currency),
                    const SizedBox(height: 24),
                  ],

                  // Daily Spending Chart
                  if (_dailySpending.isNotEmpty) ...[
                    Text(
                      'Daily Spending',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildDailySpendingChart(trip.currency),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildBudgetCard(trip, double totalSpent, double progress) {
    final hasExceeded = trip.budget != null && totalSpent > trip.budget!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Budget Overview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (hasExceeded)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Over Budget',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
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
                            color: hasExceeded ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
                if (trip.budget != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Budget',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${trip.currency} ${trip.budget!.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ],
                  ),
              ],
            ),
            if (trip.budget != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  color: hasExceeded
                      ? Colors.red
                      : progress > 0.8
                          ? Colors.orange
                          : Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(1)}% of budget used',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsRow(int receiptCount, double totalSpent, String currency) {
    final avgSpending = receiptCount > 0 ? totalSpent / receiptCount : 0.0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.receipt_long,
            label: 'Receipts',
            value: receiptCount.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.category,
            label: 'Categories',
            value: _categorySpending.length.toString(),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            icon: Icons.trending_up,
            label: 'Avg/Receipt',
            value: '$currency ${avgSpending.toStringAsFixed(0)}',
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(String currency) {
    if (_categorySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final total = _categorySpending.values.fold<double>(0, (a, b) => a + b);
    
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: _categorySpending.entries.map((entry) {
            final category = SpendingCategory.findByName(entry.key);
            final percentage = (entry.value / total * 100);
            
            return PieChartSectionData(
              value: entry.value,
              title: '${percentage.toStringAsFixed(0)}%',
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              color: category?.color ?? Colors.grey,
              radius: 50,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryLegend(String currency) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categorySpending.entries.map((entry) {
        final category = SpendingCategory.findByName(entry.key);
        
        return Chip(
          avatar: CircleAvatar(
            backgroundColor: category?.color ?? Colors.grey,
            radius: 8,
          ),
          label: Text(
            '${entry.key}: $currency ${entry.value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailySpendingChart(String currency) {
    if (_dailySpending.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedDates = _dailySpending.keys.toList()..sort();
    final maxSpending = _dailySpending.values.fold<double>(0, (a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxSpending * 1.2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final date = sortedDates[group.x.toInt()];
                final amount = rod.toY;
                return BarTooltipItem(
                  '$date\n$currency ${amount.toStringAsFixed(2)}',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < sortedDates.length) {
                    final date = DateTime.parse(sortedDates[index]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('MM/dd').format(date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedDates.asMap().entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: _dailySpending[entry.value] ?? 0,
                  color: Theme.of(context).colorScheme.primary,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
