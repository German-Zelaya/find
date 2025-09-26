// widgets/universal_image_widget.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';

class UniversalImageWidget extends StatelessWidget {
  final File? file;
  final String? networkUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const UniversalImageWidget({
    Key? key,
    this.file,
    this.networkUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (file != null) {
      // Mostrar archivo local
      if (kIsWeb) {
        // En web, leer el archivo como bytes y usar Image.memory
        imageWidget = FutureBuilder<Uint8List>(
          future: file!.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return placeholder ?? Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return errorWidget ?? Container(
                width: width,
                height: height,
                color: Colors.grey[300],
                child: Icon(Icons.error, color: Colors.red),
              );
            }

            return Image.memory(
              snapshot.data!,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (context, error, stackTrace) {
                return errorWidget ?? Container(
                  width: width,
                  height: height,
                  color: Colors.grey[300],
                  child: Icon(Icons.broken_image, color: Colors.grey[600]),
                );
              },
            );
          },
        );
      } else {
        // En móvil, usar Image.file normal
        imageWidget = Image.file(
          file!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return errorWidget ?? Container(
              width: width,
              height: height,
              color: Colors.grey[300],
              child: Icon(Icons.broken_image, color: Colors.grey[600]),
            );
          },
        );
      }
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      // Mostrar imagen de red (ya manejada por ImageLoaderService en otros widgets)
      imageWidget = Image.network(
        networkUrl!,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder ?? Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600]),
          );
        },
      );
    } else {
      // Sin imagen
      imageWidget = errorWidget ?? Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Icon(Icons.image, color: Colors.grey[600]),
      );
    }

    // Aplicar borderRadius si es necesario
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}