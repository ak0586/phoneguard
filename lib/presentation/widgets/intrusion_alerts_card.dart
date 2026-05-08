import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../providers/app_provider.dart';
import '../../data/datasources/auth_service.dart';
import 'package:lost_phone_finder/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lost_phone_finder/l10n/app_localizations.dart';

class IntrusionAlertsCard extends StatefulWidget {
  const IntrusionAlertsCard({super.key});

  @override
  State<IntrusionAlertsCard> createState() => _IntrusionAlertsCardState();
}

class _IntrusionAlertsCardState extends State<IntrusionAlertsCard> with AutomaticKeepAliveClientMixin {
  int _currentIndex = 0;

  @override
  bool get wantKeepAlive => true;

  void _showLargeImage(BuildContext context, Map<String, dynamic> photo, String? userName) {
    final url = photo['url'] as String?;
    final timestamp = photo['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final lat = photo['latitude'];
    final lng = photo['longitude'];
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: url != null && url.startsWith('data:image')
                    ? Image.memory(base64Decode(url.split(',').last))
                    : (url != null ? Image.network(url) : const Icon(Icons.broken_image, color: Colors.white)),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${l10n.incidentTime}: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (lat != null)
                    ElevatedButton.icon(
                      onPressed: () => _launchMaps(lat, lng),
                      icon: const Icon(Icons.map_rounded),
                      label: Text(l10n.viewOnMaps),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete(BuildContext context, String uid, Map<String, dynamic> photo) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Photo?'),
        content: const Text('Are you sure you want to delete this intrusion capture? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel.toUpperCase(), style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService().deleteIntrusionPhoto(uid, photo);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAlive
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    final user = authProvider.user;
    final userName = authProvider.profile?.name;

    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: AuthService().intrusionPhotosStream(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final photos = snapshot.data!;
        // Sort descending by timestamp
        photos.sort((a, b) {
          final t1 = a['timestamp'] as Timestamp?;
          final t2 = b['timestamp'] as Timestamp?;
          if (t1 == null || t2 == null) return 0;
          return t2.compareTo(t1);
        });

        // Ensure index is valid
        if (_currentIndex >= photos.length) {
          _currentIndex = 0;
        }
        
        final currentPhoto = photos[_currentIndex];
        final url = currentPhoto['url'] as String?;
        final timestamp = currentPhoto['timestamp'] as Timestamp?;
        final date = timestamp?.toDate() ?? DateTime.now();
        final dateStr = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
        
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppTheme.error.withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.intrusionAlerts,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.error,
                                ),
                          ),
                          Text(
                            appProvider.isIntrusionCardCollapsed 
                                ? '${photos.length} detections • Last: $dateStr'
                                : 'Incident: $dateStr',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        appProvider.isIntrusionCardCollapsed ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                        color: Colors.grey,
                        size: 20,
                      ),
                      onPressed: () => appProvider.setIntrusionCardCollapsed(!appProvider.isIntrusionCardCollapsed),
                      tooltip: appProvider.isIntrusionCardCollapsed ? 'Show details' : 'Hide details',
                    ),
                  ],
                ),
                if (!appProvider.isIntrusionCardCollapsed) ...[
                  const SizedBox(height: 16),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => _showLargeImage(context, currentPhoto, userName),
                        child: Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5)),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: url != null 
                              ? (url.startsWith('data:image') 
                                  ? Image.memory(base64Decode(url.split(',').last), fit: BoxFit.cover)
                                  : Image.network(url, fit: BoxFit.cover))
                              : Container(color: Colors.grey[300], child: const Icon(Icons.person, size: 50)),
                          ),
                        ),
                      ),
                      
                      // Single Image Delete Button
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                            onPressed: () => _confirmDelete(context, user.uid, currentPhoto),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            tooltip: 'Delete this photo',
                          ),
                        ),
                      ),
                      
                      // Navigation Overlay
                      if (photos.length > 1) ...[
                        Positioned(
                          left: 8,
                          child: _NavButton(
                            icon: Icons.chevron_left_rounded,
                            onPressed: _currentIndex < photos.length - 1 
                              ? () => setState(() => _currentIndex++) 
                              : null,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          child: _NavButton(
                            icon: Icons.chevron_right_rounded,
                            onPressed: _currentIndex > 0 
                              ? () => setState(() => _currentIndex--) 
                              : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(photos.length, (index) {
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentIndex == index 
                            ? AppTheme.error 
                            : Colors.grey.withOpacity(0.3),
                        ),
                      );
                    }),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _NavButton({required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.3 : 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        ),
      ),
    );
  }
}
