import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:ui';
import '../services/finance_provider.dart';
import '../models/transaction_model.dart';
import '../widgets/transaction_card.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _graphScrollController = ScrollController();
  int _touchedDay = DateTime.now().day;
  bool _showAllTransactions = false;

  final List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  void _scrollToToday() {
    if (_graphScrollController.hasClients) {
      DateTime now = DateTime.now();
      if (_selectedMonth == now.month && _selectedYear == now.year) {
        double dayWidth = 75.0;
        double screenWidth = MediaQuery.of(context).size.width;
        double scrollPosition = (now.day * dayWidth) - (screenWidth / 2);
        _graphScrollController.jumpTo(
          scrollPosition.clamp(0.0, _graphScrollController.position.maxScrollExtent),
        );
      }
    }
  }

  List<TransactionModel> _getFilteredTransactions(List<TransactionModel> allTransactions) {
    List<TransactionModel> filtered = allTransactions.where((t) {
      bool matchesYear = t.date.year == _selectedYear;
      bool matchesMonth = t.date.month == _selectedMonth;
      bool matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesYear && matchesMonth && matchesSearch;
    }).toList();
    return filtered;
  }

  Future<bool?> _showDeleteConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Apakah Anda yakin ingin menghapus riwayat transaksi ini?'),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    
    if (_showAllTransactions) {
      return _buildAllTransactionsView(provider, currencyFormat);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Laporan & Riwayat', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight + 10),
            _buildSummarySection(provider, currencyFormat),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Grafik ${_months[_selectedMonth - 1]} $_selectedYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildMonthlyLineChart(provider, currencyFormat),
            const SizedBox(height: 16),
            _buildTouchedDataSection(provider, currencyFormat),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Detail Transaksi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            _buildDayTransactionsList(provider, currencyFormat),
            const SizedBox(height: 25), 
            Center(
              child: InkWell(
                onTap: () => setState(() => _showAllTransactions = true),
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt, color: Colors.blue, size: 20),
                      SizedBox(width: 8),
                      Text('Lihat Semua Transaksi', 
                        style: TextStyle(fontSize: 15, color: Colors.blue, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 140),
          ],
        ),
      ),
    );
  }

  Widget _buildAllTransactionsView(FinanceProvider provider, NumberFormat format) {
    final filteredTransactions = _getFilteredTransactions(provider.transactions);
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            setState(() => _showAllTransactions = false);
            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
          },
        ),
        title: const Text('Semua Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
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
          _buildFilterAndSearchSection(),
          Expanded(
            child: filteredTransactions.isEmpty
                ? const Center(child: Text('Tidak ada data transaksi'))
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 120), // Tambah space bawah agar tidak tertutup navbar
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return TransactionCard(
                        transaction: transaction,
                        onDelete: () async {
                          final confirmed = await _showDeleteConfirmation();
                          if (confirmed == true) {
                            provider.deleteTransaction(transaction.id!);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(FinanceProvider provider, NumberFormat format) {
    final monthTransactions = provider.transactions.where((t) => t.date.year == _selectedYear && t.date.month == _selectedMonth);
    double income = monthTransactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
    double expense = monthTransactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);
    double balance = income - expense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Text('Ringkasan ${_months[_selectedMonth - 1]} $_selectedYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSummaryRow('Pemasukan', income, Colors.green, format),
          const Divider(),
          _buildSummaryRow('Pengeluaran', expense, Colors.red, format),
          const Divider(),
          _buildSummaryRow('Saldo', balance, Colors.blue, format),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, Color color, NumberFormat format) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(format.format(amount), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMonthlyLineChart(FinanceProvider provider, NumberFormat format) {
    int daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    double dayWidth = 75.0; 
    
    Map<int, double> incomeData = {};
    Map<int, double> expenseData = {};
    double maxAmount = 10000;
    
    for (var t in provider.transactions) {
      if (t.date.year == _selectedYear && t.date.month == _selectedMonth) {
        if (t.isIncome) incomeData[t.date.day] = (incomeData[t.date.day] ?? 0) + t.amount;
        else expenseData[t.date.day] = (expenseData[t.date.day] ?? 0) + t.amount;
        maxAmount = max(maxAmount, max((incomeData[t.date.day] ?? 0), (expenseData[t.date.day] ?? 0)));
      }
    }

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    for (int i = 1; i <= daysInMonth; i++) {
      incomeSpots.add(FlSpot(i.toDouble(), incomeData[i] ?? 0));
      expenseSpots.add(FlSpot(i.toDouble(), expenseData[i] ?? 0));
    }

    return Container(
      height: 260,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        controller: _graphScrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: (daysInMonth + 1) * dayWidth, 
          child: LineChart(
            LineChartData(
              maxY: maxAmount * 1.35, 
              minY: 0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
              ),
              lineTouchData: LineTouchData(
                enabled: true,
                handleBuiltInTouches: false, 
                touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
                  if (response == null || response.lineBarSpots == null || response.lineBarSpots!.isEmpty) {
                    return;
                  }
                  if (event is FlTapUpEvent || event is FlPanDownEvent) {
                    setState(() {
                      _touchedDay = response.lineBarSpots!.first.x.toInt();
                    });
                  }
                },
                getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                  return spotIndexes.map((index) => TouchedSpotIndicatorData(
                    FlLine(color: Colors.blue.withOpacity(0.5), strokeWidth: 4),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 6,
                        color: Colors.white,
                        strokeWidth: 3,
                        strokeColor: barData.color ?? Colors.blue,
                      ),
                    ),
                  )).toList();
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 35,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      int day = value.toInt();
                      if (day >= 1 && day <= daysInMonth) {
                        bool isToday = day == DateTime.now().day && _selectedMonth == DateTime.now().month && _selectedYear == DateTime.now().year;
                        bool isTouched = day == _touchedDay;
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: GestureDetector(
                            onTap: () => setState(() => _touchedDay = day),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: isTouched ? BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ) : null,
                              child: Text(
                                day.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: (isToday || isTouched) ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? Colors.blue : (isTouched ? Colors.blue.shade700 : Colors.grey.shade600),
                                ),
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: incomeSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: Colors.green,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.green,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.green.withOpacity(0.2), Colors.green.withOpacity(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                LineChartBarData(
                  spots: expenseSpots,
                  isCurved: true,
                  preventCurveOverShooting: true,
                  color: Colors.red,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 3,
                      color: Colors.red,
                      strokeWidth: 1,
                      strokeColor: Colors.white,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [Colors.red.withOpacity(0.2), Colors.red.withOpacity(0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTouchedDataSection(FinanceProvider provider, NumberFormat format) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final isRealToday = _touchedDay == now.day && _selectedMonth == now.month && _selectedYear == now.year;
    
    final dayTransactions = provider.transactions.where((t) => 
      t.date.year == _selectedYear && 
      t.date.month == _selectedMonth && 
      t.date.day == _touchedDay
    );

    double income = dayTransactions.where((t) => t.isIncome).fold(0, (sum, t) => sum + t.amount);
    double expense = dayTransactions.where((t) => !t.isIncome).fold(0, (sum, t) => sum + t.amount);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.05), 
            blurRadius: 10, 
            spreadRadius: 1
          )
        ],
        border: Border.all(color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Data Tanggal $_touchedDay ${_months[_selectedMonth - 1]} $_selectedYear', 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16, 
                  color: isDarkMode ? Colors.white : Colors.blueGrey.shade800
                )),
              if (isRealToday)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1), 
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withOpacity(0.2))
                  ),
                  child: const Text('Hari Ini', style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem('Pemasukan', income, Colors.green, Icons.arrow_downward, isDarkMode),
              ),
              const SizedBox(width: 10),
              Container(width: 1, height: 40, color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2)),
              const SizedBox(width: 10),
              Expanded(
                child: _buildDetailItem('Pengeluaran', expense, Colors.red, Icons.arrow_upward, isDarkMode),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTransactionsList(FinanceProvider provider, NumberFormat format) {
    final dayTransactions = provider.transactions.where((t) => 
      t.date.year == _selectedYear && 
      t.date.month == _selectedMonth && 
      t.date.day == _touchedDay
    ).toList();

    if (dayTransactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: Text('Tidak ada transaksi di tanggal ini', style: TextStyle(color: Colors.grey))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: dayTransactions.length,
      itemBuilder: (context, index) {
        final transaction = dayTransactions[index];
        return TransactionCard(
          transaction: transaction,
          onDelete: () async {
            final confirmed = await _showDeleteConfirmation();
            if (confirmed == true) {
              provider.deleteTransaction(transaction.id!);
            }
          },
        );
      },
    );
  }

  Widget _buildDetailItem(String label, double amount, Color color, IconData icon, bool isDarkMode) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
          ],
        ),
        const SizedBox(height: 4),
        Text(format.format(amount), 
          style: TextStyle(
            fontSize: 15, 
            fontWeight: FontWeight.bold, 
            color: isDarkMode ? color.withOpacity(0.9) : color
          )),
      ],
    );
  }

  Widget _buildFilterAndSearchSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(10, (index) {
                        int year = DateTime.now().year - 5 + index;
                        return DropdownMenuItem(value: year, child: Text(year.toString()));
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedYear = val);
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(value: index + 1, child: Text(_months[index]));
                      }),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMonth = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari riwayat...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ],
      ),
    );
  }
}
