import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/book.dart';
import '../models/expense.dart';
import '../repos/book_repo.dart';
import '../repos/expense_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';
import 'expense_form_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> activeBooks = [];
  int _currentIndex = 0;

  List<Expense> bookExpenses = [];
  Map<int, String> memberNames = {};

  bool _isLoading = true;
  bool _isLoadingExpenses = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    final allBooks = await BookRepo.getBooks();
    activeBooks = allBooks.where((b) => !b.isClosed).toList();

    activeBooks.sort((a, b) => (b.b_id ?? 0).compareTo(a.b_id ?? 0));

    final allMembers = await MemberRepo.getMembers(onlyActive: false);
    memberNames = { for (var m in allMembers) m.m_id!: m.full_name ?? 'Unknown' };

    if (activeBooks.isNotEmpty) {
      await _loadExpensesForCurrentBook();
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadExpensesForCurrentBook() async {
    if (activeBooks.isEmpty) return;

    setState(() => _isLoadingExpenses = true);

    final allExpenses = await ExpenseRepo.getExpenses();
    bookExpenses = allExpenses.where((e) => e.b_id == activeBooks[_currentIndex].b_id).toList();

    if (!mounted) return;
    setState(() => _isLoadingExpenses = false);
  }

  void _nextBook() {
    if (_currentIndex < activeBooks.length - 1) {
      setState(() => _currentIndex++);
      _loadExpensesForCurrentBook();
    }
  }

  void _previousBook() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
      _loadExpensesForCurrentBook();
    }
  }

  Future<void> _openAddExpense() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
    );
    if (result == true) {
      // Reload expenses but keep the current book index
      _loadExpensesForCurrentBook();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeBooks.isEmpty) {
      return Center(
        child: Text(
          context.tr('no_active_books_home'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final currentBook = activeBooks[_currentIndex];

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: NeuContainer(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
              child: Row(
                children: [
                  // Previous Button
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 30),
                    color: _currentIndex > 0
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.3),
                    onPressed: _currentIndex > 0 ? _previousBook : null,
                  ),

                  // Book Details
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${context.tr('active_book')} (${_currentIndex + 1}/${activeBooks.length})',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currentBook.b_name ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Next Button
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 30),
                    color: _currentIndex < activeBooks.length - 1
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.withValues(alpha: 0.3),
                    onPressed: _currentIndex < activeBooks.length - 1 ? _nextBook : null,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(
              context.tr('recent_expenses'),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),

          Expanded(
            child: _isLoadingExpenses
                ? const Center(child: CircularProgressIndicator())
                : bookExpenses.isEmpty
                ? Center(
              child: Text(
                context.tr('no_expenses'),
                style: const TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: bookExpenses.length,
              itemBuilder: (context, index) {
                final e = bookExpenses[index];
                final payerName = memberNames[e.paid_by] ?? 'Unknown';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: NeuContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.item,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${context.tr('paid_by')}: $payerName',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${e.total_price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
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

      // ── Floating Action Button ──
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}