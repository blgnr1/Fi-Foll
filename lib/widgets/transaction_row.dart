import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class TransactionRow extends StatelessWidget {
  final Transaction transaction;
  const TransactionRow({super.key, required this.transaction});

  static final _dateFmt = DateFormat('dd MMM yyyy', 'tr_TR');

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.type == TransactionType.credit;
    final typeColor = isCredit ? AppTheme.emeraldGreen : AppTheme.crimsonDebt;
    final typeLabel = isCredit ? 'Alacak' : 'Verecek';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Slidable(
        key: ValueKey(transaction.id),
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.28,
          children: [
            SlidableAction(
              onPressed: (_) => _showPartialDialog(context),
              backgroundColor: Colors.blue.shade400,
              foregroundColor: Colors.white,
              icon: Icons.pie_chart_outline_rounded,
              label: isCredit ? 'Kısmi tahsilat' : 'Kısmi ödeme',
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
            ),
          ],
        ),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.3,
          children: [
            SlidableAction(
              onPressed: (_) => _confirmSettle(context, isCredit, typeColor),
              backgroundColor: typeColor,
              foregroundColor: Colors.white,
              icon: Icons.check_circle_outline_rounded,
              label: isCredit ? 'Tam tahsilat' : 'Tam ödeme',
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(14)),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: () => _showDetail(context),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border(
                left: BorderSide(color: typeColor, width: 4),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: typeColor.withAlpha(20),
                    child: Icon(_categoryIcon(transaction.category),
                        color: typeColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(transaction.category.name.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(typeLabel,
                                  style: TextStyle(
                                      color: typeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(_dateFmt.format(transaction.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black38)),
                        if (transaction.note != null &&
                            transaction.note!.isNotEmpty)
                          Text(transaction.note!,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.black45),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: typeColor),
                      ),
                      if (transaction.status == TransactionStatus.partial)
                        Text(
                          'Kalan: ${transaction.remainingAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                              color: Colors.black38, fontSize: 11),
                        ),
                      const SizedBox(height: 4),
                      _StatusChip(
                          status: transaction.status, isCredit: isCredit),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSettle(
      BuildContext context, bool isCredit, Color typeColor) async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Onayla'),
        content: Text(
            '${isCredit ? 'Alacak' : 'Borç'} tamamen ${isCredit ? 'tahsil edilecek' : 'ödenecek'}. Onaylıyor musunuz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: typeColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      Provider.of<WalletProvider>(context, listen: false)
          .settleTransaction(transaction.id);
    }
  }

  void _showPartialDialog(BuildContext context) {
    final ctrl = TextEditingController();
    final isCredit = transaction.type == TransactionType.credit;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Kısmi ${isCredit ? 'Tahsilat' : 'Ödeme'}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Kalan: ${transaction.remainingAmount.toStringAsFixed(2)} ${transaction.currency}',
                style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Miktar'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal', style: TextStyle(color: Colors.grey))),
          FilledButton(
            onPressed: () {
              final amount = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (amount != null &&
                  amount > 0 &&
                  amount <= transaction.remainingAmount) {
                Provider.of<WalletProvider>(context, listen: false)
                    .addPartialPayment(transaction.id, amount);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy, HH:mm', 'tr_TR');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('İşlem Detayı',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailRow('İşlem Tarihi', dateFmt.format(transaction.createdAt)),
            _DetailRow('Tür', transaction.type == TransactionType.credit ? 'Alacak' : 'Verecek'),
            _DetailRow('Kategori', transaction.category.name.toUpperCase()),
            _DetailRow('Miktar', '${transaction.amount.toStringAsFixed(2)} ${transaction.currency}'),
            if (transaction.paidAmount > 0)
              _DetailRow('Ödenen', '${transaction.paidAmount.toStringAsFixed(2)} ${transaction.currency}'),
            if (transaction.remainingAmount < transaction.amount)
              _DetailRow('Kalan', '${transaction.remainingAmount.toStringAsFixed(2)} ${transaction.currency}'),
            _DetailRow('Durum', transaction.status.name.toUpperCase()),
            if (transaction.note != null && transaction.note!.isNotEmpty)
              _DetailRow('Not', transaction.note!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  IconData _categoryIcon(TransactionCategory c) {
    switch (c) {
      case TransactionCategory.giyim:
        return Icons.shopping_bag_outlined;
      case TransactionCategory.gida:
        return Icons.restaurant_outlined;
      case TransactionCategory.ulasim:
        return Icons.directions_car_outlined;
      case TransactionCategory.konaklama:
        return Icons.hotel_outlined;
      case TransactionCategory.market:
        return Icons.local_grocery_store_outlined;
      case TransactionCategory.diger:
        return Icons.category_outlined;
    }
  }
}

class _StatusChip extends StatelessWidget {
  final TransactionStatus status;
  final bool isCredit;
  const _StatusChip({required this.status, required this.isCredit});

  @override
  Widget build(BuildContext context) {
    final labels = {
      TransactionStatus.open: 'Açık',
      TransactionStatus.partial: isCredit ? 'Kısmi tahsilat' : 'Kısmi ödeme',
      TransactionStatus.settled: 'Kapatıldı',
    };
    final colors = {
      TransactionStatus.open: Colors.orange,
      TransactionStatus.partial: Colors.blue,
      TransactionStatus.settled: Colors.green,
    };
    final c = colors[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: c.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(labels[status]!,
          style: TextStyle(
              color: c, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(label,
                style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: Color(0xFF1C1C1E),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
