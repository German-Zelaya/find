import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String id;
  final String venueId;
  final String title;
  final String description;
  final String imageUrl;
  final DateTime eventDate;
  final DateTime createdAt;
  final bool isActive;

  EventModel({
    required this.id,
    required this.venueId,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.eventDate,
    required this.createdAt,
    required this.isActive,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return EventModel(
      id: doc.id,
      venueId: data['venueId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      eventDate: (data['eventDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'venueId': venueId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}