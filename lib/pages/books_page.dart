import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/book.dart';
import '../repos/book_repo.dart';
import '../widgets/neu_widgets.dart';
import 'book_form_page.dart';

class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  List<Book> books = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() => _isLoading = true);
    final list = await BookRepo.getBooks();
    if (!mounted) return;
    setState(() {
      books = list;
      _isLoading = false;
    });
  }

  Future<void> _openBookForm({Book? book}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => BookFormPage(book: book)),
    );

    if (result == true) _loadBooks();
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return '';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : books.isEmpty
          ? Center(child: Text(context.tr('no_books')))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: books.length,
        itemBuilder: (context, index) {
          final b = books[index];
          final isClosed = b.isClosed;

          final iconColor = isClosed
              ? Colors.grey
              : Theme.of(context).colorScheme.primary;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NeuContainer(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => _openBookForm(book: b),
                leading: CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(
                    isClosed ? Icons.lock : Icons.book,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  b.b_name ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isClosed ? Colors.grey : null,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${context.tr('start')}: ${_fmtDate(b.b_startDate)}'),
                    if (isClosed)
                      Text(
                        '${context.tr('closed')}: ${_fmtDate(b.b_closeDate)}',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                      )
                    else
                       Text(
                        context.tr('active'),
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title:  Text(context.tr('delete_book')),
                        content: Text('${context.tr('sure_to_delete')} ${b.b_name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text(context.tr('cancel'))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child:  Text(context.tr('delete'), style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && b.b_id != null) {
                      await BookRepo.deleteBook(b.b_id!);
                      _loadBooks();
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBookForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}