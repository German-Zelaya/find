import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import '../models/zone_model.dart';
import '../models/venue_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import '../models/premium_banner_model.dart';

class DatabaseService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // Configuración de Cloudinary
  static const String cloudinaryCloudName = 'dbht3dwaq';
  static const String cloudinaryUploadPreset = 'findapp';

  // CLOUDINARY - SUBIDA DE IMÁGENES (ACTUALIZADA PARA WEB)
  Future<String?> _uploadToCloudinary(File imageFile, String folder) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', url);

      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.fields['folder'] = 'fin-d/$folder';

      if (kIsWeb) {
        // Para web, usar bytes directamente
        final bytes = await imageFile.readAsBytes();
        final multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: imageFile.path.split('/').last.isNotEmpty
              ? imageFile.path.split('/').last
              : 'image.jpg',
        );
        request.files.add(multipartFile);
      } else {
        // Para móvil, usar path normal
        final multipartFile = await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(responseData);
        return jsonResponse['secure_url'] as String;
      } else {
        print('Error uploading to Cloudinary: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  // ZONES CON CLOUDINARY
  Stream<List<ZoneModel>> getZones() {
    return _firestore
        .collection('zones')
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ZoneModel.fromFirestore(doc)).toList());
  }

  Future<bool> addZone(String name, File? imageFile) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadToCloudinary(imageFile, 'zones') ?? '';
      }

      QuerySnapshot snapshot = await _firestore.collection('zones').orderBy('order', descending: true).limit(1).get();
      int nextOrder = snapshot.docs.isNotEmpty ? (snapshot.docs.first.data() as Map)['order'] + 1 : 1;

      ZoneModel zone = ZoneModel(
        id: '',
        name: name,
        imageUrl: imageUrl,
        order: nextOrder,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('zones').add(zone.toFirestore());
      return true;
    } catch (e) {
      print('Error adding zone: $e');
      return false;
    }
  }

  Future<bool> updateZone(String zoneId, String name, File? imageFile) async {
    try {
      Map<String, dynamic> updateData = {'name': name};

      if (imageFile != null) {
        String? imageUrl = await _uploadToCloudinary(imageFile, 'zones');
        if (imageUrl != null) {
          updateData['imageUrl'] = imageUrl;
        }
      }

      await _firestore.collection('zones').doc(zoneId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating zone: $e');
      return false;
    }
  }

  Future<bool> deleteZone(String zoneId) async {
    try {
      await _firestore.collection('zones').doc(zoneId).delete();
      return true;
    } catch (e) {
      print('Error deleting zone: $e');
      return false;
    }
  }

  // VENUES CON CLOUDINARY
  Stream<List<VenueModel>> getVenuesByZone(String zoneId) {
    return _firestore
        .collection('venues')
        .where('zoneId', isEqualTo: zoneId)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VenueModel.fromFirestore(doc)).toList());
  }

  Stream<List<VenueModel>> getAllVenues() {
    return _firestore
        .collection('venues')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => VenueModel.fromFirestore(doc)).toList());
  }

  Future<VenueModel?> getVenueById(String venueId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('venues').doc(venueId).get();
      if (doc.exists) {
        return VenueModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting venue: $e');
      return null;
    }
  }

  Future<bool> addVenue(VenueModel venue, File? mainImageFile, List<File> galleryFiles) async {
    try {
      String mainImageUrl = '';
      if (mainImageFile != null) {
        mainImageUrl = await _uploadToCloudinary(mainImageFile, 'venues') ?? '';
      }

      List<String> galleryUrls = [];
      for (File file in galleryFiles) {
        String? url = await _uploadToCloudinary(file, 'venues/gallery');
        if (url != null) {
          galleryUrls.add(url);
        }
      }

      QuerySnapshot snapshot = await _firestore
          .collection('venues')
          .where('zoneId', isEqualTo: venue.zoneId)
          .orderBy('order', descending: true)
          .limit(1)
          .get();
      int nextOrder = snapshot.docs.isNotEmpty ? (snapshot.docs.first.data() as Map)['order'] + 1 : 1;

      VenueModel newVenue = VenueModel(
        id: '',
        name: venue.name,
        zoneId: venue.zoneId,
        description: venue.description,
        mainImageUrl: mainImageUrl,
        galleryImages: galleryUrls,
        location: venue.location,
        socialMedia: venue.socialMedia,
        isPremium: venue.isPremium,
        order: nextOrder,
        createdAt: DateTime.now(),
        ownerId: venue.ownerId,
      );

      await _firestore.collection('venues').add(newVenue.toFirestore());
      return true;
    } catch (e) {
      print('Error adding venue: $e');
      return false;
    }
  }

  Future<bool> updateVenue(String venueId, Map<String, dynamic> updates, {
    File? mainImageFile,
    List<File>? galleryFiles,
  }) async {
    try {
      Map<String, dynamic> updateData = Map.from(updates);

      if (mainImageFile != null) {
        String? imageUrl = await _uploadToCloudinary(mainImageFile, 'venues');
        if (imageUrl != null) {
          updateData['mainImageUrl'] = imageUrl;
        }
      }

      if (galleryFiles != null && galleryFiles.isNotEmpty) {
        List<String> galleryUrls = [];
        for (File file in galleryFiles) {
          String? url = await _uploadToCloudinary(file, 'venues/gallery');
          if (url != null) {
            galleryUrls.add(url);
          }
        }
        updateData['galleryImages'] = galleryUrls;
      }

      await _firestore.collection('venues').doc(venueId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating venue: $e');
      return false;
    }
  }

  Future<bool> deleteVenue(String venueId) async {
    try {
      await _firestore.collection('venues').doc(venueId).delete();
      return true;
    } catch (e) {
      print('Error deleting venue: $e');
      return false;
    }
  }

  Future<bool> updateVenueOrder(String venueId, int newOrder) async {
    try {
      await _firestore.collection('venues').doc(venueId).update({'order': newOrder});
      return true;
    } catch (e) {
      print('Error updating venue order: $e');
      return false;
    }
  }

  // PREMIUM BANNERS CON CLOUDINARY
  Stream<List<PremiumBannerModel>> getPremiumBanners() {
    return _firestore
        .collection('premium_banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => PremiumBannerModel.fromFirestore(doc)).toList());
  }

  Future<bool> addPremiumBanner(File imageFile, String title, String description, String? linkedVenueId) async {
    try {
      String? imageUrl = await _uploadToCloudinary(imageFile, 'premium-banners');

      if (imageUrl == null) {
        print('Error: No se pudo subir la imagen a Cloudinary');
        return false;
      }

      QuerySnapshot snapshot = await _firestore.collection('premium_banners').orderBy('order', descending: true).limit(1).get();
      int nextOrder = snapshot.docs.isNotEmpty ? (snapshot.docs.first.data() as Map)['order'] + 1 : 1;

      PremiumBannerModel banner = PremiumBannerModel(
        id: '',
        imageUrl: imageUrl,
        title: title,
        description: description,
        order: nextOrder,
        isActive: true,
        linkedVenueId: linkedVenueId,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('premium_banners').add(banner.toFirestore());
      print('Banner agregado exitosamente con Cloudinary');
      return true;
    } catch (e) {
      print('Error adding premium banner: $e');
      return false;
    }
  }

  Future<bool> deletePremiumBanner(String bannerId) async {
    try {
      await _firestore.collection('premium_banners').doc(bannerId).update({'isActive': false});
      return true;
    } catch (e) {
      print('Error deleting premium banner: $e');
      return false;
    }
  }

  Future<bool> updateBannerOrder(String bannerId, int newOrder) async {
    try {
      await _firestore.collection('premium_banners').doc(bannerId).update({'order': newOrder});
      return true;
    } catch (e) {
      print('Error updating banner order: $e');
      return false;
    }
  }

  // EVENTS CON CLOUDINARY
  Stream<List<EventModel>> getEventsByVenue(String venueId) {
    return _firestore
        .collection('events')
        .where('venueId', isEqualTo: venueId)
        .where('isActive', isEqualTo: true)
        .orderBy('eventDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromFirestore(doc)).toList());
  }

  Future<bool> addEvent(EventModel event, File? imageFile) async {
    try {
      String imageUrl = '';
      if (imageFile != null) {
        imageUrl = await _uploadToCloudinary(imageFile, 'events') ?? '';
      }

      EventModel newEvent = EventModel(
        id: '',
        venueId: event.venueId,
        title: event.title,
        description: event.description,
        imageUrl: imageUrl,
        eventDate: event.eventDate,
        createdAt: DateTime.now(),
        isActive: true,
      );

      await _firestore.collection('events').add(newEvent.toFirestore());
      return true;
    } catch (e) {
      print('Error adding event: $e');
      return false;
    }
  }

  Future<bool> updateEvent(String eventId, Map<String, dynamic> updates, {File? imageFile}) async {
    try {
      Map<String, dynamic> updateData = Map.from(updates);

      if (imageFile != null) {
        String? imageUrl = await _uploadToCloudinary(imageFile, 'events');
        if (imageUrl != null) {
          updateData['imageUrl'] = imageUrl;
        }
      }

      await _firestore.collection('events').doc(eventId).update(updateData);
      return true;
    } catch (e) {
      print('Error updating event: $e');
      return false;
    }
  }

  Future<bool> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).update({'isActive': false});
      return true;
    } catch (e) {
      print('Error deleting event: $e');
      return false;
    }
  }

  // USERS
  Stream<List<UserModel>> getUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  // UTILIDADES - CORREGIDAS PARA WEB Y MÓVIL
  Future<File?> pickImage() async {
    try {
      if (kIsWeb) {
        // Usar file_picker en web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          final file = result.files.first;
          if (file.bytes != null) {
            return _SimpleWebFile(file.bytes!, file.name);
          }
        }
      } else {
        // Usar image_picker en móvil (CORREGIDO)
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (image != null) {
          return File(image.path);
        }
      }

      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  Future<List<File>> pickMultipleImages() async {
    try {
      if (kIsWeb) {
        // file_picker para múltiples imágenes en web
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: true,
          withData: true,
        );

        if (result != null && result.files.isNotEmpty) {
          List<File> files = [];
          for (var file in result.files) {
            if (file.bytes != null) {
              files.add(_SimpleWebFile(file.bytes!, file.name));
            }
          }
          return files;
        }
      } else {
        // CORREGIDO: pickMultipleMedia en lugar de pickMultiImage
        final List<XFile> images = await _picker.pickMultipleMedia(
          imageQuality: 85,
          limit: 10,
        );
        return images.map((image) => File(image.path)).toList();
      }

      return [];
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}

// Clase simple para web que solo implementa lo necesario
class _SimpleWebFile implements File {
  final Uint8List _bytes;
  final String _name;

  _SimpleWebFile(this._bytes, this._name);

  @override
  String get path => _name;

  @override
  Future<Uint8List> readAsBytes() async => _bytes;

  @override
  Future<bool> exists() async => true;

  @override
  int lengthSync() => _bytes.length;

  @override
  Future<int> length() async => _bytes.length;

  // Implementaciones mínimas requeridas
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}