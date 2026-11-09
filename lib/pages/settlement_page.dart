import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/book.dart';
import '../models/expense.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import '../models/settlement_engine.dart';
import '../repos/book_repo.dart';
import '../repos/expense_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';
import 'book_settlement_page.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({super.key});

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Member> allMembers = [];
  List<Book> allBooks = [];
  List<Expense> allExpenses = [];
  List<MemberSettlement> overallSettlements = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    allMembers = await MemberRepo.getMembers(onlyActive: false);
    allBooks = await BookRepo.getBooks();
    allExpenses = await ExpenseRepo.getExpenses();

    Map<int, double> totalPaidMap = {};
    for (var e in allExpenses) {
      totalPaidMap[e.paid_by] = (totalPaidMap[e.paid_by] ?? 0) + e.total_price;
    }

    Map<int, double> totalShareMap = {};

    for (var book in allBooks) {
      final bookExpenses = allExpenses.where((e) => e.b_id == book.b_id).toList();
      final bookTotal = bookExpenses.fold(0.0, (sum, e) => sum + e.total_price);

      if (bookTotal == 0) continue;

      final assignedIds = await BookRepo.getAssignedMemberIds(book.b_id!);
      if (assignedIds.isEmpty) continue;

      final sharePerMember = bookTotal / assignedIds.length;

      for (var mId in assignedIds) {
        totalShareMap[mId] = (totalShareMap[mId] ?? 0) + sharePerMember;
      }
    }

    overallSettlements = allMembers.map((m) {
      final paid = totalPaidMap[m.m_id] ?? 0.0;
      final share = totalShareMap[m.m_id] ?? 0.0;
      return MemberSettlement(
        m_id: m.m_id!,
        memberName: m.full_name ?? 'Unknown',
        totalPaid: paid,
        totalShare: share,
      );
    }).toList();

    overallSettlements.sort((a, b) => a.memberName.compareTo(b.memberName));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          tabs: [
            Tab(text: context.tr('overall')),
            Tab(text: context.tr('per_book')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverallTab(),
              _buildPerBookTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallTab() {
    if (overallSettlements.isEmpty) {
      return  Center(child: Text(context.tr('no_data')));
    }

    final transactions = SettlementEngine.calculateTransactions(overallSettlements);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (transactions.isNotEmpty) ...[
          Text(
            context.tr('settle_up'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),
          ...transactions.map((t) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(t.fromName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                        ),
                        Text(t.toName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    Text('${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            );
          }).toList(),
        ] else if (overallSettlements.any((s) => s.balance.abs() > 0.01)) ...[
          const Center(child: Text("Calculating..."))
        ] else ...[
           Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(context.tr('all_settle_up'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],

         SizedBox(height: 24),
        Text(
          context.tr('individual_balances'),
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(height: 12),

        ...overallSettlements.map((s) {
          final isPositive = s.balance >= 0;
          final isZero = s.balance.abs() <= 0.01;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeuContainer(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (isZero)
                         Text(context.tr('all_settle_up'), style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                      else
                        Text(
                          isPositive ? '${context.tr('gets')}: ${s.balance.toStringAsFixed(2)}' : '${context.tr('owes')}: ${s.balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.redAccent),
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('${context.tr('total_paid')}: ${s.totalPaid.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                  Text('${context.tr('total_share')}: ${s.totalShare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPerBookTab() {
    if (allBooks.isEmpty) {
      return Center(child: Text(context.tr('no_book_a')));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allBooks.length,
      itemBuilder: (context, index) {
        final b = allBooks[index];
        final bookExpenses = allExpenses.where((e) => e.b_id == b.b_id).toList();
        final total = bookExpenses.fold(0.0, (sum, e) => sum + e.total_price);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => BookSettlementPage(book: b)),
              );
            },
            child: NeuContainer(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: b.isClosed ? Colors.grey : Theme.of(context).colorScheme.primary,
                  child: Icon(b.isClosed ? Icons.lock : Icons.book, color: Colors.white, size: 20),
                ),
                title: Text(b.b_name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(b.isClosed ? context.tr('closed') : context.tr('active')),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${context.tr('total_expenses')}: ${total.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                    ),
                    const Icon(Icons.chevron_right, size: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}