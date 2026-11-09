import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../repos/member_repo.dart';
import '../repos/transaction_repo.dart';
import '../widgets/neu_widgets.dart';
import 'transaction_member_detail_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Member> members = [];
  Map<int, double> memberBalances = {}; // Positive = They owe you, Negative = You owe them
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    members = await MemberRepo.getMembers(onlyActive: false);
    final transactions = await TransactionRepo.getTransactions();

    Map<int, double> balances = {};
    for (var t in transactions) {
      if (t.is_settled) continue; // Skip settled transactions

      double amount = t.amount;
      // If 'gets', it means you owe them, so we subtract from their balance.
      if (t.type == 'gets') amount = -amount;

      balances[t.m_id] = (balances[t.m_id] ?? 0) + amount;
    }

    if (!mounted) return;
    setState(() {
      memberBalances = balances;
      _isLoading = false;
    });
  }

  void _openMemberTransactions(Member m) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionMemberDetailPage(member: m)),
    );
    if (result == true) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
          ? Center(child: Text(context.tr('no_member')))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          final balance = memberBalances[m.m_id] ?? 0.0;
          final isPositive = balance > 0;
          final isZero = balance == 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => _openMemberTransactions(m),
              child: NeuContainer(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      (m.full_name?.isNotEmpty ?? false) ? m.full_name![0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(m.full_name ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (isZero)
                        Text('Settled', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))
                      else
                        Text(
                          isPositive
                              ? '\$${balance.toStringAsFixed(2)}'
                              : '-\$${balance.abs().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isPositive ? Colors.green : Colors.redAccent,
                          ),
                        ),
                      Text(
                        isZero ? '' : (isPositive ? context.tr('owes_you') : context.tr('you_owe')),
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}