import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/book.dart';
import '../models/member.dart';
import '../repos/book_repo.dart';
import '../repos/expense_repo.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';

class BookFormPage extends StatefulWidget {
  final Book? book;
  const BookFormPage({super.key, this.book});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String b_name;
  DateTime? b_startDate;
  DateTime? b_closeDate;
  bool _isSaving = false;

  // Members logic
  List<Member> allMembers = [];
  final Set<int> selectedMemberIds = {};
  final Set<int> lockedMemberIds = {};
  bool _isLoadingMembers = true;

  bool get isEditingClosedBook => widget.book != null && widget.book!.isClosed;

  @override
  void initState() {
    super.initState();
    b_name = widget.book?.b_name ?? '';
    b_startDate = widget.book?.b_startDate ?? DateTime.now();
    b_closeDate = widget.book?.b_closeDate;
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    final members = await MemberRepo.getMembers(onlyActive: false);

    List<int> assigned = [];
    if (widget.book?.b_id != null) {
      assigned = await BookRepo.getAssignedMemberIds(widget.book!.b_id!);
    }
    final locked = await ExpenseRepo.getMembersWithExpensesForBook(widget.book!.b_id!);
    lockedMemberIds.addAll(locked);

    if (!mounted) return;
    setState(() {
      allMembers = members;
      selectedMemberIds.addAll(assigned);
      _isLoadingMembers = false;
    });
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = (isStart ? b_startDate : b_closeDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (isStart) {
        b_startDate = picked;
      } else {
        b_closeDate = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.book == null ? context.tr('add_book') : context.tr('update_book')),
        content:  Text(context.tr('sure_to_save')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: Text(context.tr('save'))),
        ],
      ),
    );

    if (confirm != true) return;

    _formKey.currentState!.save();
    setState(() => _isSaving = true);

    final b = Book(
      b_id: widget.book?.b_id,
      b_name: b_name,
      b_startDate: b_startDate,
      b_closeDate: b_closeDate,
    );

    final int bookId;
    if (widget.book == null) {
      bookId = await BookRepo.addBook(b);
    } else {
      await BookRepo.updateBook(b);
      bookId = widget.book!.b_id!;
    }

    await BookRepo.saveAssignedMembers(bookId, selectedMemberIds.toList());

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  String _fmt(DateTime? d) =>
      d == null ? 'Not set' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book == null ? context.tr('add_book') : context.tr('book_details')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NeuContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: b_name,
                      enabled: !isEditingClosedBook,
                      decoration:  InputDecoration(
                        labelText: context.tr('book_name'),
                        border: InputBorder.none,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.tr('required') : null,
                      onSaved: (v) => b_name = v?.trim() ?? '',
                    ),
                    const Divider(),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title:  Text(context.tr('start_date')),
                      subtitle: Text(_fmt(b_startDate)),
                      trailing: Icon(
                        Icons.calendar_today,
                        color: isEditingClosedBook ? Colors.grey : Theme.of(context).colorScheme.primary,
                      ),
                      onTap: isEditingClosedBook ? null : () => _pickDate(isStart: true),
                    ),
                    const Divider(),
                    if (widget.book != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(context.tr('end_date')),
                        subtitle: Text(_fmt(b_closeDate)),
                        trailing: Icon(
                          Icons.event_busy,
                          color: isEditingClosedBook ? Colors.grey : Theme.of(context).colorScheme.primary,
                        ),
                        onTap: isEditingClosedBook ? null : () => _pickDate(isStart: false),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 8),
                child: Text(
                  context.tr('assign_member'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),

              if (_isLoadingMembers)
                const Center(child: CircularProgressIndicator())
              else if (allMembers.isEmpty)
                 Center(child: Text(context.tr('no_member_2.')))
              else
                NeuContainer(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: allMembers.map((m) {
                      final isSelected = selectedMemberIds.contains(m.m_id);
                      return CheckboxListTile(
                        title: Text(m.full_name ?? 'Unknown'),
                        subtitle: m.phone != null ? Text(m.phone!) : null,
                        value: isSelected,
                        activeColor: Theme.of(context).colorScheme.primary,
                        // Disable checkboxes if book is closed
                        onChanged: (isEditingClosedBook || lockedMemberIds.contains(m.m_id))
                            ? null
                            : (bool? val) {
                          setState(() {
                            if (val == true) {
                              selectedMemberIds.add(m.m_id!);
                            } else {
                              selectedMemberIds.remove(m.m_id);
                            }
                          });
                        },
                        secondary: lockedMemberIds.contains(m.m_id)
                            ? Icon(Icons.lock, color: Colors.grey, size: 20,)
                        : null,
                      );
                    }).toList(),
                  ),
                ),

              const SizedBox(height: 32),

              if (!isEditingClosedBook)
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

              if (isEditingClosedBook)
                 Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      context.tr('closed_book_cannot_edit'),
                      style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}