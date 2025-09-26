import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import '../models/user_model.dart';
import '../services/image_loader_service.dart';

class CustomNavBar extends StatelessWidget {
  final String title;
  final UserModel? user;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final bool showBackButton;

  const CustomNavBar({
    Key? key,
    required this.title,
    this.user,
    this.onBackPressed,
    this.onMenuPressed,
    this.showBackButton = false,
  }) : super(key: key);

  // Widget para mostrar avatar usando ImageLoaderService en web
  Widget _buildAvatarWidget(UserModel user) {
    if (user.photoUrl == null) {
      return _buildInitialsAvatar(user);
    }

    if (kIsWeb) {
      // En web, usar ImageLoaderService para evitar errores CORS
      return FutureBuilder<Uint8List?>(
        future: ImageLoaderService.loadImageBytes(user.photoUrl!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: Colors.grey[300],
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
                  ),
                ),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return Image.memory(
              snapshot.data!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return _buildInitialsAvatar(user);
              },
            );
          } else {
            return _buildInitialsAvatar(user);
          }
        },
      );
    } else {
      // En móvil, usar CachedNetworkImage normal
      return CachedNetworkImage(
        imageUrl: user.photoUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[300],
          child: Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A148C)),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildInitialsAvatar(user),
      );
    }
  }

  // Widget de respaldo con iniciales
  Widget _buildInitialsAvatar(UserModel user) {
    return Container(
      color: Color(0xFF4A148C),
      child: Center(
        child: Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Botón de retroceso o espacio
          if (showBackButton)
            IconButton(
              icon: Icon(Icons.arrow_back, color: Color(0xFF4A148C)),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          else
            SizedBox(width: 48),

          // Título
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4A148C),
              ),
            ),
          ),

          // Avatar del usuario o botón de menú
          if (user != null)
            GestureDetector(
              onTap: onMenuPressed,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF4A148C),
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: _buildAvatarWidget(user!),
                ),
              ),
            )
          else
            SizedBox(width: 48),
        ],
      ),
    );
  }
}