import 'package:flutter/material.dart';

import 'package:arsiv_app/core/theme/app_theme.dart';

/// Hesabım ekranı (Keşfet'teki avatardan açılır).
///
/// Geçici sade tasarım: Emir'in tasarımı gelince gövde değişecek,
/// constructor ve callback'ler aynı kalmalı.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.name,
    required this.email,
    required this.isPremium,
    required this.onUpgrade,
    required this.onLogout,
  });

  final String name;
  final String email;
  final bool isPremium;
  final VoidCallback onUpgrade;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Scaffold(
      appBar: AppBar(title: const Text('Hesabım')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.cardHigh,
            child: Text(
              initial,
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ListTile(
            tileColor: AppColors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            leading: const Icon(Icons.workspace_premium, color: AppColors.gold),
            title: const Text('Üyelik'),
            trailing: Text(isPremium ? 'Premium' : 'Ücretsiz'),
          ),
          const SizedBox(height: 24),
          if (!isPremium)
            FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text("Premium'a geç"),
            ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: onLogout,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Çıkış yap'),
          ),
        ],
      ),
    );
  }
}
