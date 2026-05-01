import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../../data/datasources/auth_service.dart';
import 'package:lost_phone_finder/core/theme/app_theme.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class IntrusionAlertsCard extends StatelessWidget {
  const IntrusionAlertsCard({super.key});

  void _showLargeImage(BuildContext context, Map<String, dynamic> photo, String? userName) {
    final url = photo['url'] as String?;
    final timestamp = photo['timestamp'] as Timestamp?;
    final date = timestamp?.toDate() ?? DateTime.now();
    final lat = photo['latitude'];
    final lng = photo['longitude'];

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
                    'Incident Time: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (lat != null)
                    ElevatedButton.icon(
                      onPressed: () => _launchMaps(lat, lng),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('VIEW ON GOOGLE MAPS'),
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
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
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.error.withOpacity(0.3), width: 1.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Text(
                      'Intrusion Alerts (${photos.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.error,
                          ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        AuthService().clearIntrusionPhotos(user.uid);
                      },
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text('Clear All', style: TextStyle(color: AppTheme.error)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 125,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final url = photo['url'] as String?;
                      final timestamp = photo['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate() ?? DateTime.now();
                      
                      final dateStr = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: GestureDetector(
                          onTap: () => _showLargeImage(context, photo, userName),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: url != null 
                                    ? (url.startsWith('data:image') 
                                        ? Image.memory(base64Decode(url.split(',').last), width: 85, height: 85, fit: BoxFit.cover)
                                        : Image.network(url, width: 85, height: 85, fit: BoxFit.cover))
                                    : Container(width: 85, height: 85, color: Colors.grey[300], child: const Icon(Icons.person)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                dateStr,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
