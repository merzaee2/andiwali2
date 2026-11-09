import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/expense.dart';
import '../models/book.dart';
import '../models/member.dart';
import '../repos/expense_repo.dart';
import '../repos/book_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;
  const ExpenseFormPage({super.key, this.expense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _formKey = GlobalKey<FormState>();

  late String item;
  late double total_price;
  late DateTime date;
  int? selectedBookId;
  int? selectedMemberId;

  List<Book> allBooks = [];
  List<Member> allMembers = [];

  // Map to store which members belong to which book: { b_id: [m_id1, m_id2] }
  Map<int, List<int>> bookMembersMap = {};

  // The lists actually shown in the dropdowns
  List<Book> displayBooks = [];
  List<Member> displayMembers = [];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isReadOnly = false;

  @override
  void initState() {
    super.initState();
    item = widget.expense?.item ?? '';
    total_price = widget.expense?.total_price ?? 0;
    date = widget.expense?.date ?? DateTime.now();
    selectedBookId = widget.expense?.b_id;
    selectedMemberId = widget.expense?.paid_by;

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    allBooks = await BookRepo.getBooks();
    allMembers = await MemberRepo.getMembers(onlyActive: false);

    // 1. Fetch all book-member relationships
    for (var book in allBooks) {
      if (book.b_id != null) {
        final assignedIds = await BookRepo.getAssignedMemberIds(book.b_id!);
        bookMembersMap[book.b_id!] = assignedIds;
      }
    }

    bool bookIsClosed = false;
    if (widget.expense != null) {
      final book = allBooks.firstWhere((b) => b.b_id == widget.expense!.b_id, orElse: () => Book());
      bookIsClosed = book.isClosed;
    }

    if (!mounted) return;
    setState(() {
      if (widget.expense != null) {
        displayBooks = allBooks;
      } else {
        displayBooks = allBooks.where((b) => !b.isClosed).toList();
      }

      // Auto-select book if only one exists
      if (widget.expense == null && displayBooks.length == 1) {
        selectedBookId = displayBooks.first.b_id;
      }

      // 2. Filter the members based on the selected book
      _filterMembersForSelectedBook();

      _isReadOnly = bookIsClosed;
      _isLoading = false;
    });
  }

  // Helper function to filter members
  void _filterMembersForSelectedBook() {
    if (selectedBookId == null) {
      displayMembers = []; // No book selected = no members to show
      return;
    }

    // Get the IDs of members assigned to this book
    final assignedIds = bookMembersMap[selectedBookId] ?? [];

    // Filter the master member list
    // If editing, we must also include the member who originally paid (even if they were removed from the book later)
    displayMembers = allMembers.where((m) {
      final isAssigned = assignedIds.contains(m.m_id);
      final isCurrentPayer = widget.expense != null && m.m_id == widget.expense!.paid_by;
      final isActive = m.is_active;

      // Show them if they are assigned to the book OR if they are the original payer
      // But if adding new, only show assigned active members.
      if (widget.expense != null) {
        return isAssigned || isCurrentPayer;
      } else {
        return isAssigned && isActive;
      }
    }).toList();

    // 3. Clear the selected member if they are no longer in the filtered list
    if (selectedMemberId != null) {
      final stillValid = displayMembers.any((m) => m.m_id == selectedMemberId);
      if (!stillValid) {
        selectedMemberId = null;
      }
    }

    // Auto-select if there is only one member for this book
    if (widget.expense == null && displayMembers.length == 1) {
      selectedMemberId = displayMembers.first.m_id;
    }
  }

  Future<void> _pickDate() async {
    if (_isReadOnly) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _save() async {
    if (_isReadOnly) return;
    if (!_formKey.currentState!.validate()) return;
    if (selectedBookId == null || selectedMemberId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('select_book_member'))),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final e = Expense(
      e_id: widget.expense?.e_id,
      b_id: selectedBookId!,
      item: item,
      total_price: total_price,
      date: date,
      paid_by: selectedMemberId!,
      is_settled: widget.expense?.is_settled ?? false,
    );

    if (widget.expense == null) {
      await ExpenseRepo.addExpense(e);
    } else {
      await ExpenseRepo.updateExpense(e);
    }

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? context.tr('add_expense') : context.tr('expense_details')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_isReadOnly)
                Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    context.tr('expense_belongs_to_closed_book'),
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                ),

              NeuContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: item,
                      enabled: !_isReadOnly,
                      decoration:  InputDecoration(
                        labelText: context.tr('item_desc'),
                        border: InputBorder.none,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.tr('required') : null,
                      onSaved: (v) => item = v?.trim() ?? '',
                    ),
                    const Divider(),
                    TextFormField(
                      initialValue: widget.expense != null ? total_price.toString() : '',
                      enabled: !_isReadOnly,
                      decoration:  InputDecoration(
                        labelText: context.tr('total_price'),
                        border: InputBorder.none,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return context.tr('required');
                        if (double.tryParse(v) == null) return context.tr('invalid_num');
                        return null;
                      },
                      onSaved: (v) => total_price = double.parse(v!),
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title:  Text(context.tr('date')),
                      subtitle: Text(_fmtDate(date)),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: _isReadOnly ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      onTap: _pickDate,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              NeuContainer(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      decoration:  InputDecoration(labelText: context.tr('book')),
                      initialValue: selectedBookId,
                      items: displayBooks.map((b) {
                        return DropdownMenuItem(
                          value: b.b_id,
                          child: Text(
                            '${b.b_name}${b.isClosed ? " (Closed)" : ""}',
                            style: TextStyle(
                              color: b.isClosed ? Colors.grey : null,
                              fontStyle: b.isClosed ? FontStyle.italic : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isReadOnly ? null : (val) {
                        setState(() {
                          selectedBookId = val;
                          // When the book changes, re-filter the members!
                          _filterMembersForSelectedBook();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration:  InputDecoration(labelText: context.tr('paid_by')),
                      initialValue: selectedMemberId,
                      // If no members are assigned, show a hint
                      hint: Text(displayMembers.isEmpty ? context.tr('no_member_2') : "", style: TextStyle(fontSize: 14),),
                      items: displayMembers.map((m) {
                        return DropdownMenuItem(
                          value: m.m_id,
                          child: Text(
                            m.full_name ?? 'Unknown',
                            style: TextStyle(
                              color: !m.is_active ? Colors.grey : null,
                              fontStyle: !m.is_active ? FontStyle.italic : null,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _isReadOnly || displayMembers.isEmpty
                          ? null
                          : (val) => setState(() => selectedMemberId = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (!_isReadOnly)
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