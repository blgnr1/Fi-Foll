import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/add_transaction_sheet.dart';
import '../widgets/transaction_row.dart';
import 'history_screen.dart';

class TransactionScreen extends StatelessWidget {
  final Account account;
  const TransactionScreen({super.key, required this.account});

  void _showAddTransactionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddTransactionDialog(accountId: account.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        title: Text(account.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'İşlem Geçmişi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => HistoryScreen(account: account)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            onPressed: () => _showAddTransactionDialog(context),
          ),
        ],
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, _) {
          final active = provider.getActiveTransactions(account.id);
          if (active.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.black26),
                  SizedBox(height: 16),
                  Text('Aktif işlem yok.',
                      style: TextStyle(color: Colors.black45, fontSize: 16)),
                  SizedBox(height: 4),
                  Text('Eklemek için + butonuna dokunun.',
                      style: TextStyle(color: Colors.black26, fontSize: 13)),
                ],
              ),
            );
          }
          return ListView.builder(
            physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics()),
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: active.length,
            itemBuilder: (_, i) => TransactionRow(transaction: active[i]),
          );
        },
      ),
      bottomNavigationBar: _PersonSummaryFooter(accountId: account.id),
    );
  }
}

class _PersonSummaryFooter extends StatelessWidget {
  final String accountId;
  const _PersonSummaryFooter({required this.accountId});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<WalletProvider>(context);
    final tryFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');
    final usdFmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

    final credit = provider.getTotalCredits(accountId);
    final debt = provider.getTotalDebts(accountId);
    final netTRY = credit - debt;
    final netUSD = provider.getNetUSD(accountId);
    final isPositive = netTRY >= 0;

    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, bottomPadding > 0 ? bottomPadding : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(8),
              blurRadius: 12,
              offset: const Offset(0, -4))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SummaryChip(
                    label: 'Toplam Alacak',
                    value: tryFmt.format(credit),
                    color: AppTheme.emeraldGreen),
                _SummaryChip(
                    label: 'Toplam Verecek',
                    value: tryFmt.format(debt),
                    color: AppTheme.crimsonDebt,
                    alignRight: true),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Net Durum',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tryFmt.format(netTRY),
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? AppTheme.emeraldGreen
                              : AppTheme.crimsonDebt),
                    ),
                    Text(usdFmt.format(netUSD),
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  const _SummaryChip(
      {required this.label,
      required this.value,
      required this.color,
      this.alignRight = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w600, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1C1C1E))),
      ],
    );
  }
}
