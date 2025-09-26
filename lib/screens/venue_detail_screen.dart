import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:typed_data';
import '../models/venue_model.dart';
import '../models/event_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/image_loader_service.dart';
import '../widgets/custom_nav_bar.dart';

class VenueDetailScreen extends StatelessWidget {
  final VenueModel venue;

  const VenueDetailScreen({Key? key, required this.venue}) : super(key: key);

  // Función para optimizar URLs de Cloudinary para web
  String optimizeCloudinaryUrl(String originalUrl, {bool isWeb = false, bool isMainImage = false}) {
    if (!isWeb) return originalUrl;

    // Si la URL ya tiene transformaciones, devolverla tal como está
    if (originalUrl.contains('/c_')) return originalUrl;

    // Si es URL de Cloudinary, agregar optimizaciones
    if (originalUrl.contains('cloudinary.com')) {
      // Buscar el punto donde insertar las transformaciones
      if (originalUrl.contains('/upload/')) {
        // Diferentes tamaños para imagen principal vs galería
        String transformation = isMainImage
            ? '/upload/c_fill,w_800,h_500,q_auto,f_auto/'
            : '/upload/c_fill,w_240,h_240,q_auto,f_auto/';

        return originalUrl.replaceFirst('/upload/', transformation);
      }
    }

    return originalUrl;
  }

  Widget _buildImageWidget(String imageUrl, bool isWeb, {bool isMainImage = false, double? width, double? height}) {
    if (isWeb) {
      // En web, usar el servicio de carga sin CORS
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(
            optimizeCloudinaryUrl(imageUrl, isWeb: isWeb, isMainImage: isMainImage)
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              width: width,
              height: height,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorWidget(width: width, height: height, isMainImage: isMainImage);
              },
            );
          } else {
            return _buildErrorWidget(width: width, height: height, isMainImage: isMainImage);
          }
        },
      );
    } else {
      // En móvil, usar CachedNetworkImage normal
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: width,
        height: height,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: Colors.grey[300],
          child: Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => _buildErrorWidget(
            width: width,
            height: height,
            isMainImage: isMainImage
        ),
      );
    }
  }

  Widget _buildErrorWidget({double? width, double? height, bool isMainImage = false}) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Icon(
        Icons.image_not_supported,
        size: isMainImage ? 64 : 40,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;
    final isWeb = kIsWeb;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          CustomNavBar(
            title: venue.name,
            user: user,
            showBackButton: true,
          ),
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isWeb ? 1000 : double.infinity,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen principal con fix de CORS
                      Container(
                        height: isWeb ? 350 : 250,
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(horizontal: isWeb ? 20 : 0),
                        child: ClipRRect(
                          borderRadius: isWeb ? BorderRadius.circular(15) : BorderRadius.zero,
                          child: _buildImageWidget(
                            venue.mainImageUrl,
                            isWeb,
                            isMainImage: true,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),

                      // Contenido
                      Container(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              venue.name,
                              style: TextStyle(
                                fontSize: isWeb ? 32 : 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A148C),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              venue.description,
                              style: TextStyle(
                                fontSize: isWeb ? 18 : 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: 20),

                            // Galería de imágenes con fix de CORS
                            if (venue.galleryImages.isNotEmpty) ...[
                              Text(
                                'CARTELERA',
                                style: TextStyle(
                                  fontSize: isWeb ? 24 : 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                height: isWeb ? 150 : 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: venue.galleryImages.length,
                                  itemBuilder: (context, index) {
                                    final imageSize = isWeb ? 150.0 : 120.0;
                                    return Container(
                                      width: imageSize,
                                      margin: EdgeInsets.only(right: 12),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: _buildImageWidget(
                                          venue.galleryImages[index],
                                          isWeb,
                                          width: imageSize,
                                          height: imageSize,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 20),
                            ],

                            // Botón de ubicación
                            if (venue.location.isNotEmpty) ...[
                              ElevatedButton.icon(
                                onPressed: () => _openLocation(venue.location),
                                icon: Icon(Icons.location_on),
                                label: Text('ubicación'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(double.infinity, isWeb ? 55 : 50),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                            ],

                            // Redes sociales
                            if (venue.socialMedia.isNotEmpty) ...[
                              Text(
                                'Whats app y redes',
                                style: TextStyle(
                                  fontSize: isWeb ? 22 : 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF4A148C),
                                ),
                              ),
                              SizedBox(height: 12),
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: venue.socialMedia.entries.map((entry) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        children: [
                                          Icon(
                                            _getSocialIcon(entry.key),
                                            color: Colors.white,
                                            size: isWeb ? 28 : 24,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: () => _openSocialMedia(entry.key, entry.value),
                                              child: Text(
                                                entry.key.toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isWeb ? 18 : 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        return Icons.message;
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'twitter':
        return Icons.alternate_email;
      default:
        return Icons.link;
    }
  }

  void _openLocation(String location) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$location';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _openSocialMedia(String platform, String handle) async {
    String url;
    switch (platform.toLowerCase()) {
      case 'whatsapp':
        url = 'https://wa.me/$handle';
        break;
      case 'facebook':
        url = 'https://facebook.com/$handle';
        break;
      case 'instagram':
        url = 'https://instagram.com/$handle';
        break;
      case 'twitter':
        url = 'https://twitter.com/$handle';
        break;
      default:
        url = handle;
    }

    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}