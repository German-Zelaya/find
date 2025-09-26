import 'package:cloud_firestore/cloud_firestore.dart';

class PremiumBannerModel {
  final String id;
  final String imageUrl;
  final String title;
  final String description;
  final int order;
  final bool isActive;
  final String? linkedVenueId; // Opcional: puede enlazar a un local específico
  final DateTime createdAt;

  PremiumBannerModel({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.description,
    required this.order,
    required this.isActive,
    this.linkedVenueId,
    required this.createdAt,
  });

  factory PremiumBannerModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PremiumBannerModel(
      id: doc.id,
      imageUrl: data['imageUrl'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      order: data['order'] ?? 0,
      isActive: data['isActive'] ?? true,
      linkedVenueId: data['linkedVenueId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'description': description,
      'order': order,
      'isActive': isActive,
      'linkedVenueId': linkedVenueId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}