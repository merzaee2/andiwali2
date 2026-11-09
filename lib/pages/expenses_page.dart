import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/expense.dart';
import '../repos/expense_repo.dart';
import '../repos/book_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';
import 'expense_form_page.dart';

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  List<Expense> expenses = [];
  Map<int, String> bookNames = {};
  Map<int, String> memberNames = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final expList = await ExpenseRepo.getExpenses();
    final bList = await BookRepo.getBooks();
    final mList = await MemberRepo.getMembers(onlyActive: false);

    if (!mounted) return;
    setState(() {
      expenses = expList;
      bookNames = { for (var b in bList) b.b_id!: b.b_name ?? 'Unknown' };
      memberNames = { for (var m in mList) m.m_id!: m.full_name ?? 'Unknown' };
      _isLoading = false;
    });
  }

  Future<void> _openExpenseForm({Expense? expense}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: expense)),
    );
    if (result == true) _loadData();
  }

  Future<void> _deleteExpense(Expense e) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('delete_expense')),
        content: Text('${context.tr('sure_to_delete')} "${e.item}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && e.e_id != null) {
      await ExpenseRepo.deleteExpense(e.e_id!);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : expenses.isEmpty
          ? Center(child: Text(context.tr('no_expenses')))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: expenses.length,
        itemBuilder: (context, index) {
          final e = expenses[index];
          final bookName = bookNames[e.b_id] ?? 'Unknown Book';
          final payerName = memberNames[e.paid_by] ?? 'Unknown';

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GestureDetector(
              onTap: () => _openExpenseForm(expense: e),
              child: NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            e.item,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),

                        // Price and Status Column
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\$${e.total_price.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Status Row
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.is_settled ? Icons.check_circle : Icons.pending,
                                  size: 14,
                                  color: e.is_settled ? Colors.green : Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  e.is_settled ? context.tr('settled') : context.tr('unsettled'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: e.is_settled ? Colors.green : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Delete Button
                        IconButton(
                          constraints: const BoxConstraints(), // Removes default IconButton padding
                          padding: const EdgeInsets.only(left: 8, bottom: 12),
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () => _deleteExpense(e),
                        )
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${context.tr('book')}: $bookName', style: const TextStyle(fontSize: 13)),
                    Text('${context.tr('paid_by')}: $payerName', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openExpenseForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}