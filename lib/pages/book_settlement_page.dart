import 'package:flutter/material.dart';
import '../models/book.dart';
import '../models/member.dart';
import '../models/settlement.dart';
import '../models/settlement_engine.dart';
import '../repos/book_repo.dart';
import '../repos/expense_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';
import 'package:andiwali_app/localization.dart';

class BookSettlementPage extends StatefulWidget {
  final Book book;
  const BookSettlementPage({super.key, required this.book});

  @override
  State<BookSettlementPage> createState() => _BookSettlementPageState();
}

class _BookSettlementPageState extends State<BookSettlementPage> {
  List<MemberSettlement> settlements = [];
  bool _isLoading = true;
  double totalBookExpense = 0;
  double sharePerMember = 0;

  @override
  void initState() {
    super.initState();
    _calculateSettlement();
  }

  Future<void> _calculateSettlement() async {
    final allExpenses = await ExpenseRepo.getExpenses();
    final bookExpenses = allExpenses.where((e) => e.b_id == widget.book.b_id).toList();

    totalBookExpense = bookExpenses.fold(0.0, (sum, e) => sum + e.total_price);

    final assignedIds = await BookRepo.getAssignedMemberIds(widget.book.b_id!);

    if (assignedIds.isNotEmpty) {
      sharePerMember = totalBookExpense / assignedIds.length;
    }

    final allMembers = await MemberRepo.getMembers(onlyActive: false);

    Map<int, double> paidMap = {};
    for (var e in bookExpenses) {
      paidMap[e.paid_by] = (paidMap[e.paid_by] ?? 0) + e.total_price;
    }

    settlements = assignedIds.map((mId) {
      final member = allMembers.firstWhere((m) => m.m_id == mId, orElse: () => Member(full_name: 'Unknown'));
      final paid = paidMap[mId] ?? 0.0;

      return MemberSettlement(
        m_id: mId,
        memberName: member.full_name ?? 'Unknown',
        totalPaid: paid,
        totalShare: sharePerMember,
      );
    }).toList();

    settlements.sort((a, b) => a.memberName.compareTo(b.memberName));

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final transactions = SettlementEngine.calculateTransactions(settlements);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.b_name ?? 'Book Settlement'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          NeuContainer(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(context.tr('total_expenses'), style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('\$${totalBookExpense.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade400),
                Column(
                  children: [
                    Text(context.tr('share_per_member'), style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text('\$${sharePerMember.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

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
                      Text('\$${t.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ] else if (settlements.isNotEmpty) ...[
             Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(context.tr('all_settle_for_this_book'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],

          SizedBox(height: 24),
          Text(
            context.tr('individual_balances'),
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(height: 12),

          if (settlements.isEmpty)
             Center(child: Text(context.tr('no_member_2')))
          else
            ...settlements.map((s) {
              final isPositive = s.balance >= 0;
              final isZero = s.balance.abs() <= 0.01;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NeuContainer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.memberName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${context.tr('paid')}: \$${s.totalPaid.toStringAsFixed(2)} '
                            ),
                          ],
                        ),
                      ),
                      if (isZero)
                        Text(context.tr('settled'), style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                      else
                        Text(
                          isPositive ? '+\$${s.balance.toStringAsFixed(2)}' : '-\$${s.balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPositive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}