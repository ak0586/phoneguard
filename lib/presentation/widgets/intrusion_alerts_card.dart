import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../../data/datasources/auth_service.dart';
import '../../core/theme/app_theme.dart';

class IntrusionAlertsCard extends StatelessWidget {
  const IntrusionAlertsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      final url = photo['url'] as String?;
                      final timestamp = photo['timestamp'] as Timestamp?;
                      final date = timestamp?.toDate() ?? DateTime.now();
                      
                      // Format date nicely
                      final dateStr = '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

                      return Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: url != null 
                                ? (url.startsWith('data:image') 
                                    ? Image.memory(base64Decode(url.split(',').last), width: 80, height: 80, fit: BoxFit.cover)
                                    : Image.network(url, width: 80, height: 80, fit: BoxFit.cover))
                                : Container(width: 80, height: 80, color: Colors.grey[300]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              dateStr,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
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
