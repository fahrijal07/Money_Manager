import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/finance_provider.dart';
import '../models/saving_model.dart';

class SavingScreen extends StatefulWidget {
  const SavingScreen({super.key});

  @override
  State<SavingScreen> createState() => _SavingScreenState();
}

class _SavingScreenState extends State<SavingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetController = TextEditingController();

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

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Tabungan?'),
        content: const Text('Apakah Anda yakin ingin menghapus data tabungan ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddSavingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Target Tabungan Baru'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Tabungan'),
                validator: (val) => val!.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _targetController,
                decoration: const InputDecoration(labelText: 'Target Uang', prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                onChanged: (value) => _formatCurrency(_targetController, value),
                validator: (val) => val!.isEmpty ? 'Target tidak boleh kosong' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                final saving = SavingModel(
                  name: _nameController.text,
                  targetAmount: double.parse(_targetController.text.replaceAll('.', '')),
                  savedAmount: 0,
                );
                Provider.of<FinanceProvider>(context, listen: false).addSaving(saving);
                Navigator.pop(context);
                _nameController.clear();
                _targetController.clear();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddMoneyDialog(SavingModel saving) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Tambah ke ${saving.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Uang yang ditambahkan akan otomatis dicatat sebagai pengeluaran.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Jumlah', prefixText: 'Rp '),
              keyboardType: TextInputType.number,
              onChanged: (value) => _formatCurrency(amountController, value),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                final addedAmount = double.parse(amountController.text.replaceAll('.', ''));
                final updatedSaving = SavingModel(
                  id: saving.id,
                  name: saving.name,
                  targetAmount: saving.targetAmount,
                  savedAmount: saving.savedAmount + addedAmount,
                );
                Provider.of<FinanceProvider>(context, listen: false).updateSaving(updatedSaving, addedAmount: addedAmount);
                Navigator.pop(context);
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Tabungan Saya', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 10),
          Expanded(
            child: provider.savings.isEmpty
                ? const Center(child: Text('Belum ada target tabungan'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120),
                    itemCount: provider.savings.length,
                    itemBuilder: (context, index) {
                      final saving = provider.savings[index];
                      final shortfall = saving.targetAmount - saving.savedAmount;
                      final isCompleted = shortfall <= 0;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(saving.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                                    onPressed: () async {
                                      final confirmed = await _showDeleteConfirmation();
                                      if (confirmed == true) {
                                        provider.deleteSaving(saving.id!);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              LinearPercentIndicator(
                                lineHeight: 14.0,
                                percent: saving.progress > 1.0 ? 1.0 : saving.progress,
                                center: Text("${(saving.progress * 100).toStringAsFixed(1)}%", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                progressColor: Colors.green,
                                backgroundColor: Colors.grey.shade200,
                                barRadius: const Radius.circular(7),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Terkumpul: ${currencyFormat.format(saving.savedAmount)}', style: const TextStyle(fontSize: 12)),
                                  Text('Target: ${currencyFormat.format(saving.targetAmount)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Kekurangan:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                      Text(
                                        isCompleted ? 'Selesai!' : currencyFormat.format(shortfall),
                                        style: TextStyle(
                                          fontSize: 14, 
                                          fontWeight: FontWeight.bold, 
                                          color: isCompleted ? Colors.green : Colors.redAccent
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (!isCompleted)
                                    ElevatedButton.icon(
                                      onPressed: () => _showAddMoneyDialog(saving),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tabung'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 115),
        child: FloatingActionButton(
          onPressed: _showAddSavingDialog,
          shape: const CircleBorder(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
