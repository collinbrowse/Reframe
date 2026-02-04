import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/config/env_config.dart';
import '../../../../core/providers/app_providers.dart';

class StravaConnectScreen extends ConsumerStatefulWidget {
  const StravaConnectScreen({super.key});

  @override
  ConsumerState<StravaConnectScreen> createState() => _StravaConnectScreenState();
}

class _StravaConnectScreenState extends ConsumerState<StravaConnectScreen> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final stravaConnection = ref.watch(stravaConnectionProvider);
    final isConnected = stravaConnection.value != null;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Strava'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Strava logo/branding
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFFC4C02),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.directions_run,
                size: 50,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            Text(
              isConnected ? 'Connected to Strava' : 'Connect to Strava',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isConnected
                  ? 'Your activities are syncing automatically'
                  : 'Sync your activities to create amazing content',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Connection status / Connected account
            if (isConnected) ...[
              _buildConnectedCard(stravaConnection.value!),
            ] else ...[
              _buildBenefits(),
            ],

            const Spacer(),

            // Configuration notice
            if (!EnvConfig.isStravaConfigured) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppTheme.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Strava API not configured. See setup instructions.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Connect/Disconnect button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isConnecting
                    ? null
                    : () => isConnected ? _disconnect() : _connect(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? AppTheme.error
                      : const Color(0xFFFC4C02),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isConnecting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(isConnected ? Icons.link_off : Icons.link),
                          const SizedBox(width: 8),
                          Text(
                            isConnected ? 'Disconnect' : 'Connect with Strava',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedCard(dynamic connection) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFFC4C02).withOpacity(0.2),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFFFC4C02),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      connection.athleteName ?? 'Athlete',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          size: 16,
                          color: AppTheme.success,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white12),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSyncButton(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncButton() {
    return OutlinedButton.icon(
      onPressed: _syncActivities,
      icon: const Icon(Icons.sync),
      label: const Text('Sync Now'),
    );
  }

  Widget _buildBenefits() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _BenefitItem(
            icon: Icons.sync,
            title: 'Auto-sync Activities',
            description: 'Your runs, rides, and workouts sync automatically',
          ),
          const SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.photo_library,
            title: 'Smart Matching',
            description: 'We match your photos and videos to each activity',
          ),
          const SizedBox(height: 16),
          _BenefitItem(
            icon: Icons.bar_chart,
            title: 'Activity Stats',
            description: 'Include pace, distance, and heart rate in your videos',
          ),
        ],
      ),
    );
  }

  Future<void> _connect() async {
    if (!EnvConfig.isStravaConfigured) {
      _showSetupInstructions();
      return;
    }

    setState(() => _isConnecting = true);

    try {
      final stravaService = ref.read(stravaServiceProvider);
      final launched = await stravaService.launchAuthorization();
      
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open Strava authorization'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Disconnect Strava?'),
        content: const Text(
          'Your synced activities will remain on this device, but new activities won\'t sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isConnecting = true);
      
      try {
        await ref.read(stravaConnectionProvider.notifier).disconnect();
        ref.read(analyticsProvider).trackStravaDisconnected();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Disconnected from Strava'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isConnecting = false);
        }
      }
    }
  }

  Future<void> _syncActivities() async {
    try {
      await ref.read(activitiesProvider.notifier).syncFromStrava();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activities synced!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync failed: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSetupInstructions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Strava API Setup',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'To connect Strava, you need to set up API credentials:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              _SetupStep(
                number: '1',
                title: 'Create Strava App',
                description: 'Go to strava.com/settings/api and create a new application',
              ),
              const SizedBox(height: 16),
              _SetupStep(
                number: '2',
                title: 'Get Credentials',
                description: 'Copy your Client ID and Client Secret',
              ),
              const SizedBox(height: 16),
              _SetupStep(
                number: '3',
                title: 'Configure App',
                description: 'Add credentials to your environment variables:\n\nSTRAVA_CLIENT_ID=your_id\nSTRAVA_CLIENT_SECRET=your_secret',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFFC4C02).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFFFC4C02), size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SetupStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _SetupStep({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppTheme.primaryColor,
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
