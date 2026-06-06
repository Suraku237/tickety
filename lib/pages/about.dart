import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  bool _isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);

    return Scaffold(
      backgroundColor: AppTheme.surface(isDark),
      appBar: AppBar(
        title: const Text('About TICKETY'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surface(isDark),
        foregroundColor: AppTheme.textPrimary(isDark),
        iconTheme: IconThemeData(color: AppTheme.textPrimary(isDark)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.card(isDark),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.border(isDark)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.textMuted(isDark).withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.crimson,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.crimson.withOpacity(0.3),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.confirmation_num_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'TICKETY',
                      style: TextStyle(
                        color: AppTheme.textPrimary(isDark),
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'The modern queue experience for people and places.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMuted(isDark),
                        fontSize: 14,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Version 1.0.0',
                      style: TextStyle(
                        color: AppTheme.textMuted(isDark).withOpacity(0.65),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'About our app',
                style: TextStyle(
                  color: AppTheme.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'TICKETY is built to turn waiting into moving. It helps businesses and service providers offer fast, transparent, and paperless ticketing, so guests can reserve their place from anywhere and enjoy a polished experience from arrival to service.',
                style: TextStyle(
                  color: AppTheme.textMuted(isDark),
                  fontSize: 14,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'What makes TICKETY special',
                style: TextStyle(
                  color: AppTheme.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 14),
              _featureTile(
                title: 'Remote queueing',
                description: 'Join the line before you arrive and receive live updates on your waiting status.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _featureTile(
                title: 'Live wait times',
                description: 'See estimated service times instantly and plan your visit with confidence.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _featureTile(
                title: 'Smart notifications',
                description: 'Get alerts when your ticket is ready, so you never miss your turn.',
                isDark: isDark,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _pill('Instant check-in', isDark),
                  _pill('Digital tickets', isDark),
                  _pill('Live wait times', isDark),
                  _pill('Venue-ready', isDark),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Designed for modern venues',
                style: TextStyle(
                  color: AppTheme.textPrimary(isDark),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'TICKETY helps teams deliver premium service in restaurants, clinics, events, government offices, and customer service centers.',
                style: TextStyle(
                  color: AppTheme.textMuted(isDark),
                  fontSize: 14,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 24),
              _teamCard('Amina', 'UI/UX Designer', isDark),
              const SizedBox(height: 12),
              _teamCard('Bruno', 'Backend Developer', isDark),
              const SizedBox(height: 12),
              _teamCard('Andre', 'Frontend Developer', isDark),
              const SizedBox(height: 12),
              _teamCard('Rayan', 'Full Stack Developer', isDark),
              const SizedBox(height: 12),
              _teamCard('Bachirou', 'DevOps Engineer', isDark),
              const SizedBox(height: 28),
              Center(
                child: Text(
                  'Thank you for choosing TICKETY. Designed to keep people moving with confidence.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppTheme.textMuted(isDark),
                    fontSize: 13,
                    height: 1.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureTile({
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppTheme.textPrimary(isDark),
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textMuted(isDark),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface(isDark),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppTheme.textPrimary(isDark),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _teamCard(String name, String role, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.card(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border(isDark)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.crimson.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: AppTheme.crimson,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: AppTheme.textPrimary(isDark),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: TextStyle(
                  color: AppTheme.textMuted(isDark),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
