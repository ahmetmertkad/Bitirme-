import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../models/plant_scan_model.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'full_screen_image_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final FirestoreService _db = FirestoreService();
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view your history')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'My Garden',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 24,
            color: Theme.of(context).textTheme.displayLarge?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PlantScanModel>>(
        stream: _db.getUserPlantScans(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppPadding.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                           BoxShadow(
                             color: AppColors.primary.withValues(alpha: 0.1),
                             blurRadius: 40,
                             spreadRadius: 10,
                           ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.yard_outlined,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppPadding.xl),
                    Text(
                      "Your Garden is Empty",
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        color: AppColors.textMain,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppPadding.md),
                    const Text(
                      "Every great garden starts with a single seedling.\nSnap a photo of your first leaf to begin tracking.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final scans = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(AppPadding.md),
            itemCount: scans.length,
            itemBuilder: (context, index) {
              final scan = scans[index];
              final dateStr = "${scan.date.day}/${scan.date.month}/${scan.date.year}";
              
              final isHealthy = scan.plantIllnessId.toLowerCase().contains('healthy');
              final statusColor = isHealthy ? AppColors.healthy : AppColors.diseased;

              return Card(
                margin: const EdgeInsets.only(bottom: AppPadding.md),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(AppPadding.sm),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Hero(
                      tag: 'scan_image_${scan.plantId ?? scan.date.millisecondsSinceEpoch}',
                      child: Image.network(
                        scan.imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: AppColors.primaryLight.withValues(alpha: 0.2),
                            child: const Icon(Icons.broken_image, color: AppColors.primary),
                          );
                        },
                      ),
                    ),
                  ),
                  title: Text(
                    scan.plantIllnessId,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Scanned on $dateStr'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      scan.plantTypeId,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  onTap: () {
                    if (scan.imageUrl.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageScreen(
                            imageUrl: scan.imageUrl,
                            heroTag: 'scan_image_${scan.plantId ?? scan.date.millisecondsSinceEpoch}',
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
