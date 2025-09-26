import 'package:cloud_firestore/cloud_firestore.dart';

class VenueModel {
  final String id;
  final String name;
  final String zoneId;
  final String description;
  final String mainImageUrl;
  final List<String> galleryImages;
  final String location;
  final Map<String, String> socialMedia;
  final bool isPremium;
  final int order;
  final DateTime createdAt;
  final String ownerId;

  VenueModel({
    required this.id,
    required this.name,
    required this.zoneId,
    required this.description,
    required this.mainImageUrl,
    required this.galleryImages,
    required this.location,
    required this.socialMedia,
    required this.isPremium,
    required this.order,
    required this.createdAt,
    required this.ownerId,
  });

  factory VenueModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VenueModel(
      id: doc.id,
      name: data['name'] ?? '',
      zoneId: data['zoneId'] ?? '',
      description: data['description'] ?? '',
      mainImageUrl: data['mainImageUrl'] ?? '',
      galleryImages: List<String>.from(data['galleryImages'] ?? []),
      location: data['location'] ?? '',
      socialMedia: Map<String, String>.from(data['socialMedia'] ?? {}),
      isPremium: data['isPremium'] ?? false,
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      ownerId: data['ownerId'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'zoneId': zoneId,
      'description': description,
      'mainImageUrl': mainImageUrl,
      'galleryImages': galleryImages,
      'location': location,
      'socialMedia': socialMedia,
      'isPremium': isPremium,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'ownerId': ownerId,
    };
  }
}
