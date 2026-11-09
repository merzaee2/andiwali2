import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/member.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';
import 'member_form_page.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  List<Member> members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    final list = await MemberRepo.getMembers();
    if (!mounted) return;
    setState(() {
      members = list;
      _isLoading = false;
    });
  }

  Future<void> _openMemberForm({Member? member}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => MemberFormPage(member: member)),
    );

    if (result == true) {
      _loadMembers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
          ? Center(child: Text(context.tr('no_member')))
          : ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 80),
        itemCount: members.length,
        itemBuilder: (context, index) {
          final m = members[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: NeuContainer(
              padding: EdgeInsets.zero,
              child: ListTile(
                onTap: () => _openMemberForm(member: m),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    (m.full_name?.isNotEmpty ?? false) ? m.full_name![0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(
                  m.full_name ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (m.phone != null && m.phone!.isNotEmpty)
                      Text(m.phone!),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title:  Text(context.tr('delete_member')),
                        content: Text('${context.tr('sure_to_delete')} ${m.full_name}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text(context.tr('cancel'))),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child:  Text(context.tr('delete'), style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true && m.m_id != null) {
                      await MemberRepo.deleteMember(m.m_id!);
                      _loadMembers();
                    }
                  },
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openMemberForm(),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}