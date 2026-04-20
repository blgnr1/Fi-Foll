import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  final Account account;
  const HistoryScreen({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletProvider>(context);
    final settled = provider.getSettledTransactions(account.id);
    final dateFmt = DateFormat('dd MMM yyyy', 'tr_TR');

    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${account.name} — Geçmiş'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: settled.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('Kapatılmış işlem yok.',
                      style: TextStyle(color: Colors.black45, fontSize: 16)),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics()),
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: settled.length,
              itemBuilder: (_, i) {
                final t = settled[i];
                final isCredit = t.type == TransactionType.credit;
                final typeColor =
                    isCredit ? AppTheme.emeraldGreen : AppTheme.crimsonDebt;
                final typeLabel = isCredit ? 'Alacak' : 'Verecek';

                return Dismissible(
                  key: Key(t.id),
                  direction: DismissDirection.startToEnd,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('İşlemi Sil'),
                        content: const Text('Silmek istediğinize emin misin?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('İptal',
                                style: TextStyle(color: Colors.grey)),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Sil'),
                          ),
                        ],
                      ),
                    );
                  },
                  onDismissed: (direction) {
                    Provider.of<WalletProvider>(context, listen: false)
                        .deleteTransaction(t.id);
                  },
                  background: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.only(left: 20),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withAlpha(6),
                              blurRadius: 8,
                              offset: const Offset(0, 2))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: typeColor.withAlpha(20),
                          child: Icon(_categoryIcon(t.category),
                              color: typeColor, size: 20),
                        ),
                        title: Row(
                          children: [
                            Text(t.category.name.toUpperCase(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF1C1C1E))),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: typeColor.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(typeLabel,
                                  style: TextStyle(
                                      color: typeColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_outlined,
                                    size: 12, color: Colors.black38),
                                const SizedBox(width: 4),
                                Text(
                                    'Açılış: ${dateFmt.format(t.createdAt)}',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black45)),
                              ],
                            ),
                            if (t.settledAt != null)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_outline,
                                      size: 12, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                      'Kapanış: ${dateFmt.format(t.settledAt!)}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.black45)),
                                ],
                              ),
                            if (t.note != null && t.note!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(t.note!,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${t.amount.toStringAsFixed(2)} ${t.currency}',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: typeColor,
                                  decoration: TextDecoration.lineThrough),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.emeraldGreen.withAlpha(20),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text('Kapatıldı',
                                  style: TextStyle(
                                      color: AppTheme.emeraldGreen,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _categoryIcon(TransactionCategory category) {
    switch (category) {
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
