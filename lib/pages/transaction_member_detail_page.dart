import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../repos/transaction_repo.dart';
import '../widgets/neu_widgets.dart';
import 'transaction_form_page.dart';

class TransactionMemberDetailPage extends StatefulWidget {
  final Member member;
  const TransactionMemberDetailPage({super.key, required this.member});

  @override
  State<TransactionMemberDetailPage> createState() => _TransactionMemberDetailPageState();
}

class _TransactionMemberDetailPageState extends State<TransactionMemberDetailPage> {
  List<Transaction> transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);
    final all = await TransactionRepo.getTransactions();
    if (!mounted) return;
    setState(() {
      transactions = all.where((t) => t.m_id == widget.member.m_id).toList();
      _isLoading = false;
    });
  }

  Future<void> _openForm({Transaction? transaction}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => TransactionFormPage(member: widget.member, transaction: transaction)),
    );
    if (result == true) _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member.full_name ?? context.tr('transactions')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? const Center(child: Text('No transactions with this member yet.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final t = transactions[index];
          final isOwes = t.type == 'owes';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NeuContainer(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _openForm(transaction: t),
                title: Text(t.note?.isNotEmpty == true ? t.note! : (isOwes ? 'Owes me' : 'I owe')),
                subtitle: Text('${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isOwes ? '+\$${t.amount.toStringAsFixed(2)}' : '-\$${t.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isOwes ? Colors.green : Colors.redAccent,
                      ),
                    ),
                    if (t.is_settled)
                      const Text('Settled', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}