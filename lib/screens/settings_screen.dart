import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  Widget _buildSettingOption(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, size: 24, color: Colors.red),
          title: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        const Divider(thickness: 1),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingOption(
                Icons.notifications,
                'Notifications',
                () => print('Notifications tapped'),
              ),
              _buildSettingOption(
                Icons.lock,
                'Privacy',
                () => print('Privacy tapped'),
              ),
              _buildSettingOption(
                Icons.language,
                'Language',
                () => print('Language tapped'),
              ),
              const SizedBox(height: 20),
              const Text(
                'Support',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              _buildSettingOption(
                Icons.info_outline,
                'About Us',
                () => print('About Us tapped'),
              ),
              _buildSettingOption(
                Icons.policy,
                'Terms & Conditions',
                () => print('Terms tapped'),
              ),
              _buildSettingOption(
                Icons.privacy_tip,
                'Privacy Policy',
                () => print('Privacy Policy tapped'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}