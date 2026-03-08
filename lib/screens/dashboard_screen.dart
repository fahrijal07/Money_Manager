import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();
  late AnimationController _themeController;

  @override
  void initState() {
    super.initState();
    _themeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _themeController.dispose();
    super.dispose();
  }

  void _formatCurrency(TextEditingController controller, String value) {
    if (value.isNotEmpty) {
      String cleanedValue = value.replaceAll('.', '');
      double? amount = double.tryParse(cleanedValue);
      if (amount != null) {
        String formatted = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(amount).trim();
        controller.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: const Text('Tambah Transaksi'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Pengeluaran'), icon: Icon(Icons.remove_circle_outline, size: 16)),
                        ButtonSegment(value: true, label: Text('Pemasukan'), icon: Icon(Icons.add_circle_outline, size: 16)),
                      ],
                      selected: {_isIncome},
                      onSelectionChanged: (Set<bool> newSelection) {
                        setModalState(() {
                          _isIncome = newSelection.first;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Judul',
                      ),
                      validator: (val) => val!.isEmpty ? 'Judul tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 15),
                    TextFormField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah',
                        prefixText: 'Rp ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => _formatCurrency(_amountController, value),
                      validator: (val) => val!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 10),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Tanggal: ${DateFormat('dd MMMM yyyy').format(_selectedDate)}', style: const TextStyle(fontSize: 14)),
                      trailing: const Icon(Icons.calendar_today, size: 20),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null) setModalState(() => _selectedDate = picked);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final amount = double.parse(_amountController.text.replaceAll('.', ''));
                  final transaction = TransactionModel(
                    title: _titleController.text,
                    amount: amount,
                    category: 'Umum',
                    date: _selectedDate,
                    isIncome: _isIncome,
                  );
                  Provider.of<FinanceProvider>(context, listen: false).addTransaction(transaction);
                  Navigator.pop(context);
                  _titleController.clear();
                  _amountController.clear();
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final isDarkMode = provider.themeMode == ThemeMode.dark || 
                      (provider.themeMode == ThemeMode.system && Theme.of(context).brightness == Brightness.dark);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final recentTransactions = List<TransactionModel>.from(provider.transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    final displayTransactions = recentTransactions.take(10).toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Money Manager', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: () {
              provider.toggleTheme(!isDarkMode);
              if (isDarkMode) {
                _themeController.reverse();
              } else {
                _themeController.forward();
              }
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return RotationTransition(turns: animation, child: FadeTransition(opacity: animation, child: child));
              },
              child: Icon(
                isDarkMode ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey<bool>(isDarkMode),
                // Mengubah warna kuning (orangeAccent) menjadi putih agar lebih netral
                color: isDarkMode ? Colors.white : Colors.blueGrey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.transparent),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.fetchAllData(),
        edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 5),
              _buildBalanceCard(context, provider, currencyFormat),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text('Progres Tabungan', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              _buildSavingsSummary(provider, currencyFormat),
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Transaksi Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              displayTransactions.isEmpty 
                ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Belum ada transaksi', style: TextStyle(color: Colors.grey))))
                : ListView.builder(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: displayTransactions.length,
                    itemBuilder: (context, index) {
                      return TransactionCard(transaction: displayTransactions[index]);
                    },
                  ),
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 115),
        child: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, FinanceProvider provider, NumberFormat format) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade400]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Saldo', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(format.format(provider.balance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildBalanceInfo('Pemasukan', format.format(provider.totalIncome), Icons.arrow_downward, Colors.greenAccent),
              _buildBalanceInfo('Pengeluaran', format.format(provider.totalExpense), Icons.arrow_upward, Colors.redAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String amount, IconData icon, Color color) {
    return Row(
      children: [
        CircleAvatar(radius: 15, backgroundColor: Colors.white24, child: Icon(icon, size: 16, color: color)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildSavingsSummary(FinanceProvider provider, NumberFormat format) {
    if (provider.savings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Text('Belum ada target tabungan', style: TextStyle(color: Colors.grey, fontSize: 14)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.savings.length,
      itemBuilder: (context, index) {
        final saving = provider.savings[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(saving.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                LinearPercentIndicator(
                  lineHeight: 8.0,
                  percent: saving.progress > 1.0 ? 1.0 : saving.progress,
                  progressColor: Colors.blue,
                  backgroundColor: Colors.grey.shade200,
                  barRadius: const Radius.circular(4),
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(height: 4),
                Text('${(saving.progress * 100).toStringAsFixed(1)}% dari ${format.format(saving.targetAmount)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
