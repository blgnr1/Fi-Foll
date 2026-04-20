import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/wallet_provider.dart';
import '../theme/app_theme.dart';

class AddTransactionDialog extends StatefulWidget {
  final String accountId;
  const AddTransactionDialog({super.key, required this.accountId});

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  TransactionType _type = TransactionType.credit;
  String _currency = 'TRY';
  TransactionCategory _category = TransactionCategory.diger;
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  static const _categories = [
    (TransactionCategory.giyim, Icons.shopping_bag_outlined, 'Giyim'),
    (TransactionCategory.gida, Icons.restaurant_outlined, 'Gıda'),
    (TransactionCategory.ulasim, Icons.directions_car_outlined, 'Ulaşım'),
    (TransactionCategory.konaklama, Icons.hotel_outlined, 'Konaklama'),
    (TransactionCategory.market, Icons.local_grocery_store_outlined, 'Market'),
    (TransactionCategory.diger, Icons.category_outlined, 'Diğer'),
  ];

  static const _currencies = ['TRY', 'USD', 'EUR'];

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'İşlem Ekle',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1C1C1E)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Type Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _TypeButton(
                          label: 'Alacak',
                          icon: Icons.arrow_downward_rounded,
                          color: const Color(0xFF34C759),
                          selected: _type == TransactionType.credit,
                          onTap: () => setState(() => _type = TransactionType.credit),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeButton(
                          label: 'Verecek',
                          icon: Icons.arrow_upward_rounded,
                          color: const Color(0xFFFF3B30),
                          selected: _type == TransactionType.debt,
                          onTap: () => setState(() => _type = TransactionType.debt),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount + Currency Row
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Miktar',
                            prefixIcon: Icon(Icons.payments_outlined, size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: const InputDecoration(labelText: 'Para'),
                          borderRadius: BorderRadius.circular(14),
                          items: _currencies
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (v) => setState(() => _currency = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Category Chips
                  const Text('Kategori',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categories.map((tuple) {
                      final cat = tuple.$1;
                      final icon = tuple.$2;
                      final label = tuple.$3;
                      final selected = _category == cat;
                      final typeColor = _type == TransactionType.credit
                          ? AppTheme.emeraldGreen
                          : AppTheme.crimsonDebt;
                      return GestureDetector(
                        onTap: () => setState(() => _category = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? typeColor.withAlpha(25) : AppTheme.softGray,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: selected ? typeColor : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 16, color: selected ? typeColor : Colors.black45),
                              const SizedBox(width: 6),
                              Text(label,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                                      color: selected ? typeColor : Colors.black54)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Note
                  TextField(
                    controller: _noteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Not (İsteğe Bağlı)',
                      prefixIcon: Icon(Icons.notes_outlined, size: 20),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('İptal',
                        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _save,
                    child: const Text('Kaydet',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli pozitif bir miktar giriniz.')),
      );
      return;
    }
    Provider.of<WalletProvider>(context, listen: false).addTransaction(
      Transaction(
        accountId: widget.accountId,
        type: _type,
        amount: amount,
        currency: _currency,
        category: _category,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      ),
    );
    Navigator.pop(context);
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : AppTheme.softGray,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? Colors.white : Colors.black38, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? Colors.white : Colors.black45,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
