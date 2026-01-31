import 'package:flutter/material.dart';
import 'package:tripspending/models/receipt.dart';
import 'package:tripspending/models/category.dart';
import 'package:intl/intl.dart';

/// List item widget for displaying a receipt
class ReceiptListItem extends StatelessWidget {
  final Receipt receipt;
  final VoidCallback onDelete;

  const ReceiptListItem({
    super.key,
    required this.receipt,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = SpendingCategory.findByName(receipt.category ?? 'Other');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: category?.color.withOpacity(0.2) ?? Colors.grey.withOpacity(0.2),
          child: Icon(
            category?.icon ?? Icons.receipt,
            color: category?.color ?? Colors.grey,
          ),
        ),
        title: Text(
          receipt.merchantName ?? 'Unknown Merchant',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              receipt.category ?? 'Uncategorized',
              style: TextStyle(
                color: category?.color ?? Colors.grey,
                fontSize: 12,
              ),
            ),
            if (receipt.purchaseDate != null)
              Text(
                DateFormat('MMM d, yyyy - HH:mm').format(receipt.purchaseDate!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (receipt.address != null)
              Text(
                receipt.address!,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${receipt.currency} ${receipt.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            if (receipt.latitude != null && receipt.longitude != null)
              Icon(
                Icons.location_on,
                size: 16,
                color: Theme.of(context).colorScheme.outline,
              ),
          ],
        ),
        isThreeLine: true,
        onLongPress: onDelete,
      ),
    );
  }
}
