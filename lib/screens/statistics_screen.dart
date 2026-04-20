import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  static const List<Color> _softColors = [
    Color(0xFFAEC6CF),
    Color(0xFFFFB347),
    Color(0xFFB39EB5),
    Color(0xFF77DD77),
    Color(0xFFF49AC2),
    Color(0xFFCFCFC4),
    Color(0xFFFDFD96),
    Color(0xFF836953),
    Color(0xFF779ECB),
    Color(0xFFFF6961),
  ];

  Color _getColorForIndex(int index) {
    return _softColors[index % _softColors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softGray,
      appBar: AppBar(
        title: const Text('İstatistikler'),
        backgroundColor: AppTheme.whiteSurface,
      ),
      body: Consumer<WalletProvider>(
        builder: (context, provider, child) {
          final accounts = provider.accounts;

          // Compute total credits and debts per account
          final List<Map<String, dynamic>> creditsData = [];
          final List<Map<String, dynamic>> debtsData = [];

          double totalCreditsAll = 0;
          double totalDebtsAll = 0;

          for (int i = 0; i < accounts.length; i++) {
            final acc = accounts[i];
            final credits = provider.getTotalCredits(acc.id);
            final debts = provider.getTotalDebts(acc.id);

            if (credits > 0) {
              creditsData.add({
                'account': acc,
                'value': credits,
                'color': _getColorForIndex(i),
              });
              totalCreditsAll += credits;
            }

            if (debts > 0) {
              debtsData.add({
                'account': acc,
                'value': debts,
                'color': _getColorForIndex(i),
              });
              totalDebtsAll += debts;
            }
          }

          if (creditsData.isEmpty && debtsData.isEmpty) {
            return const Center(
              child: Text(
                'Gösterilecek istatistik bulunamadı.',
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (creditsData.isNotEmpty) ...[
                  _buildSectionTitle('Toplam Alacaklar (TRY)'),
                  const SizedBox(height: 16),
                  _buildPieChartCard(creditsData, totalCreditsAll),
                  const SizedBox(height: 32),
                ],
                if (debtsData.isNotEmpty) ...[
                  _buildSectionTitle('Toplam Verecekler (TRY)'),
                  const SizedBox(height: 16),
                  _buildPieChartCard(debtsData, totalDebtsAll),
                  const SizedBox(height: 32),
                ],
                _buildSectionTitle('Genel Durum Özeti'),
                const SizedBox(height: 16),
                _buildHorizontalBar(totalCreditsAll, totalDebtsAll),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppTheme.textMain,
      ),
    );
  }

  Widget _buildPieChartCard(List<Map<String, dynamic>> data, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.whiteSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: data.map((item) {
                  final double value = item['value'];
                  final Color color = item['color'];
                  final Account acc = item['account'];
                  final double percentage = (value / total) * 100;

                  return PieChartSectionData(
                    color: color,
                    value: value,
                    title: '${percentage.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Column(
            children: data.map((item) {
              final Account acc = item['account'];
              final double value = item['value'];
              final Color color = item['color'];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        acc.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    Text(
                      '${value.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textMain,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  Widget _buildHorizontalBar(double totalCredits, double totalDebts) {
    final double total = totalCredits + totalDebts;
    if (total == 0) return const SizedBox.shrink();

    final int creditFlex = (totalCredits / total * 100).round();
    final int debtFlex = (totalDebts / total * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.whiteSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (creditFlex > 0)
                Expanded(
                  flex: creditFlex,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.emeraldGreen,
                      borderRadius: BorderRadius.horizontal(
                        left: const Radius.circular(12),
                        right: debtFlex == 0
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
                    ),
                  ),
                ),
              if (debtFlex > 0)
                Expanded(
                  flex: debtFlex,
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.crimsonDebt,
                      borderRadius: BorderRadius.horizontal(
                        right: const Radius.circular(12),
                        left: creditFlex == 0
                            ? const Radius.circular(12)
                            : Radius.zero,
                      ),
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
                  const Text('Alacaklar',
                      style: TextStyle(
                          color: AppTheme.emeraldGreen,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${totalCredits.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Verecekler',
                      style: TextStyle(
                          color: AppTheme.crimsonDebt,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('${totalDebts.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          )
        ],
      ),
    );
  }
}
