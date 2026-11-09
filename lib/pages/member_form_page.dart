import 'package:flutter/material.dart';
import '../localization.dart';
import '../models/member.dart';
import '../repos/member_repo.dart';
import '../widgets/neu_widgets.dart';

class MemberFormPage extends StatefulWidget {
  final Member? member;
  const MemberFormPage({super.key, this.member});

  @override
  State<MemberFormPage> createState() => _MemberFormPageState();
}

class _MemberFormPageState extends State<MemberFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String full_name;
  late String phone;
  bool _isSaving = false;
  late bool is_active;

  @override
  void initState() {
    super.initState();
    full_name = widget.member?.full_name ?? '';
    phone = widget.member?.phone ?? '';
    is_active = widget.member?.is_active ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Confirmation Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(widget.member == null ? context.tr('add_member') : context.tr('update_member')),
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

    final m = Member(
      m_id: widget.member?.m_id,
      full_name: full_name,
      phone: phone,
      is_active: is_active,
    );

    if (widget.member == null) {
      await MemberRepo.addMember(m);
    } else {
      await MemberRepo.updateMember(m);
    }

    if (!mounted) return;
    Navigator.pop(context, true); // Return true to trigger reload
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? context.tr('add_member') : context.tr('edit_member')),
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
                    TextFormField(
                      initialValue: full_name,
                      decoration:  InputDecoration(
                        labelText: context.tr('full_name'),
                        border: InputBorder.none,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? context.tr('required') : null,
                      onSaved: (v) => full_name = v?.trim() ?? '',
                    ),
                    const Divider(),
                    TextFormField(
                      initialValue: phone,
                      decoration:  InputDecoration(
                        labelText: context.tr('phone_number'),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.phone,
                      //validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      onSaved: (v) => phone = v?.trim() ?? '',
                    ),
                    const Divider(),
                    SwitchListTile(
                      title:  Text(context.tr('active_members')),
                      subtitle:  Text(context.tr('inActive_member')),
                      value: is_active,
                      activeThumbColor: Theme.of(context).colorScheme.primary,
                      onChanged: (val) {
                        setState(() => is_active = val);
                      },
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