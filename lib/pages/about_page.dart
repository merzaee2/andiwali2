import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // <-- Import added
import '../localization.dart';
import '../widgets/neu_widgets.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString, {bool isEmail = false}) async {
    final Uri uri = Uri.parse(isEmail ? 'mailto:$urlString' : urlString);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open $urlString')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            NeuContainer(
              borderRadius: 30,
              padding: const EdgeInsets.all(24),
              child: Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            Text(
              context.tr('app_title'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '${context.tr('app_version')} 1.0.0',
              style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),

            const SizedBox(height: 32),

            NeuContainer(
              padding: const EdgeInsets.all(20),
              child: Text(
                context.tr('app_description'),
                style: const TextStyle(fontSize: 15, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 32),

            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 12),
                child: Text(
                  context.tr('developed_by'),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),

            NeuContainer(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      context.tr('developer_name'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      context.tr('developer_email'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                    onTap: () => _launchUrl(context, context.tr('developer_email'), isEmail: true),
                  ),
                  const Divider(height: 1),

                  ListTile(
                    leading: Icon(Icons.work, color: Theme.of(context).colorScheme.primary),
                    title: Text(
                      context.tr('linkedin'),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                    onTap: () {
                      // Note: We parse the raw URL and prepend https:// if it doesn't have it
                      String url = context.tr('linkedin_url');
                      if (!url.startsWith('http')) url = 'https://$url';
                      _launchUrl(context, url);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}