import 'package:andiwali_app/pages/home_page.dart';
import 'package:andiwali_app/pages/settlement_page.dart';
import 'package:flutter/material.dart';
import 'localization.dart';
import 'pages/settings_page.dart';
import 'pages/members_page.dart';
import 'pages/books_page.dart';
import 'pages/expenses_page.dart';
import 'pages/about_page.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'pages/lock_screen.dart';
import 'providers/settings_provider.dart';
import 'pages/transactions_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  Future<void> _confirmExit(BuildContext context) async {
    Navigator.pop(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.tr('exit')),
        content: Text(context.tr('sure_to_exit')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('cancel')), // "Cancel"
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              context.tr('exit'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      final settings = context.read<SettingsProvider>();

    if (settings.isAppLockEnabled) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LockScreen()), (route) => false,
      );
    }
      Future.delayed(const Duration(milliseconds: 100), () {
        SystemNavigator.pop();
      });
    }
  }

  final List<Widget> _pages = [
    const HomePage(),                                      // Index 0
    const SettingsPage(),                                 // Index 1
    const MembersPage(),                                  // index 2
    const BooksPage(),                                    // index 3
    const ExpensesPage(),                                 // index 4
    const SettlementPage(),                               // index 5
    const AboutPage(),                                    // index 6
    const TransactionsPage(),                             // index 7

  ];

  void _onItemSelected(int index) {
    Navigator.pop(context);
    if (index >= _pages.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This page is under construction')),
      );
      return;
    }
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _selectedIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        setState(() {
          _selectedIndex = 0;
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              _selectedIndex == 0 ? context.tr('home'):
              _selectedIndex == 1 ? context.tr('settings'):
              _selectedIndex == 2 ? context.tr('members'):
              _selectedIndex == 3 ? context.tr('books'):
              _selectedIndex == 4 ? context.tr('expenses'):
              _selectedIndex == 5 ? context.tr('settlement'):
              _selectedIndex == 6 ? context.tr('about'):
              _selectedIndex == 7 ? context.tr('transactions'):
              context.tr('home')),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        drawer: _buildDrawer(context),
        body: _pages[_selectedIndex],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                const SizedBox(height: 8),
                Text(
                  context.tr('app_title'),
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          _buildDrawerItem(context, title: context.tr('home'), icon: Icons.home, index: 0),
          _buildDrawerItem(context, title: context.tr('members'), icon: Icons.people, index: 2),
          _buildDrawerItem(context, title: context.tr('books'), icon: Icons.menu_book, index: 3),
          _buildDrawerItem(context, title: context.tr('expenses'), icon: Icons.money, index: 4),
          _buildDrawerItem(context, title: context.tr('settlement'), icon: Icons.handshake, index: 5),
          const Divider(),
          _buildDrawerItem(context, title: context.tr('settings'), icon: Icons.settings, index: 1),
          _buildDrawerItem(context, title: context.tr('about'), icon: Icons.info, index: 6),
          _buildDrawerItem(context, title: context.tr('transactions'), icon: Icons.receipt_long, index: 7),
          ListTile(
            leading: const Icon(Icons.exit_to_app),
            title: Text(context.tr('exit')),
            onTap: () => _confirmExit(context),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, {required String title, required IconData icon, required int index}) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      onTap: () => _onItemSelected(index),
    );
  }
}