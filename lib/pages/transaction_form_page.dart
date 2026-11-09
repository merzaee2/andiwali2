import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/member.dart';
import '../models/transaction.dart';
import '../repos/transaction_repo.dart';
import '../widgets/neu_widgets.dart';

class TransactionFormPage extends StatefulWidget {
  final Member member;
  final Transaction? transaction;

  const TransactionFormPage({super.key, required this.member, this.transaction});

  @override
  State<TransactionFormPage> createState() => _TransactionFormPageState();
}

class _TransactionFormPageState extends State<TransactionFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String amount;
  late String note;
  late DateTime date;
  late String type; // 'owes' or 'gets'
  bool _isSettled = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    amount = widget.transaction?.amount.toString() ?? '';
    note = widget.transaction?.note ?? '';
    date = widget.transaction?.date ?? DateTime.now();
    type = widget.transaction?.type ?? 'owes';
    _isSettled = widget.transaction?.is_settled ?? false;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final t = Transaction(
      t_id: widget.transaction?.t_id,
      m_id: widget.member.m_id!,
      amount: double.parse(amount),
      date: date,
      note: note.trim().isEmpty ? null : note.trim(),
      type: type,
      is_settled: _isSettled,
    );

    if (widget.transaction == null) {
      await TransactionRepo.addTransaction(t);
    } else {
      await TransactionRepo.updateTransaction(t);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transaction == null ? context.tr('add_transaction') : context.tr('transaction_details')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Type Toggle
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(value: 'owes', label: Text(context.tr('owes')), icon: const Icon(Icons.arrow_downward, color: Colors.green)),
                        ButtonSegment(value: 'gets', label: Text(context.tr('gets')), icon: const Icon(Icons.arrow_upward, color: Colors.red)),
                      ],
                      selected: {type},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() => type = newSelection.first);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      initialValue: amount,
                      decoration: InputDecoration(labelText: context.tr('amount'), border: InputBorder.none),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.tr('required');
                        if (double.tryParse(v) == null) return context.tr('invalid_num');
                        return null;
                      },
                      onSaved: (v) => amount = v!,
                    ),
                    const Divider(),
                    TextFormField(
                      initialValue: note,
                      decoration: InputDecoration(labelText: context.tr('note'), border: InputBorder.none),
                      onSaved: (v) => note = v ?? '',
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(context.tr('date')),
                      subtitle: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                      trailing: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                      onTap: _pickDate,
                    ),
                    const Divider(),
                    SwitchListTile(
                      title: Text(context.tr('settled')),
                      value: _isSettled,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) => setState(() => _isSettled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(context.tr('save'), style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}