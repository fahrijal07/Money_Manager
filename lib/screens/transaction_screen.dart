import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_card.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedCategory = 'Makanan';
  bool _isIncome = false;
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = ['Makanan', 'Transportasi', 'Hiburan', 'Belanja', 'Gaji', 'Lainnya'];

  void _showAddTransactionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tambah Transaksi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ToggleButtons(
                isSelected: [!_isIncome, _isIncome],
                onPressed: (index) => setState(() => _isIncome = index == 1),
                borderRadius: BorderRadius.circular(10),
                children: const [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Pengeluaran')),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Text('Pemasukan')),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Jumlah', border: OutlineInputBorder(), prefixText: 'Rp '),
                keyboardType: TextInputType.number,
                validator: (val) => val!.isEmpty ? 'Jumlah tidak boleh kosong' : null,
              ),
              const SizedBox(height: 15),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
                decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              ListTile(
                title: Text('Tanggal: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2101),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final transaction = TransactionModel(
                      title: _titleController.text,
                      amount: double.parse(_amountController.text),
                      category: _selectedCategory,
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
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Transaksi')),
      body: provider.transactions.isEmpty
          ? const Center(child: Text('Belum ada transaksi'))
          : ListView.builder(
              itemCount: provider.transactions.length,
              itemBuilder: (context, index) {
                final transaction = provider.transactions[index];
                return TransactionCard(
                  transaction: transaction,
                  onDelete: () => provider.deleteTransaction(transaction.id!),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
