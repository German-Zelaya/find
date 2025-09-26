## Aplicación Find

### Descripción General
Find es una aplicación móvil desarrollada en Flutter que permite a los usuarios descubrir locales de discotecas o bares por zonas geográficas. La aplicación incluye funcionalidades tanto para clientes como para administradores.

### Características Principales

#### Para Usuarios
- **Exploración por zonas**: Los usuarios pueden navegar por diferentes zonas y descubrir locales
- **Búsqueda**: Sistema de búsqueda integrado para encontrar zonas específicas
- **Detalles de locales**: Visualización detallada de información de cada local

#### Para Administradores
- **Gestión de zonas**: Los administradores pueden agregar, editar y eliminar zonas
- **Panel de cliente**: Gestión de información de locales con imágenes y redes sociales

### Permisos Requeridos

#### iOS
- **Cámara**: Para subir imágenes de locales
- **Galería**: Para seleccionar imágenes existentes
- **Ubicación**: Para mostrar locales cercanos

### Tecnologías Utilizadas
- **Flutter**: Framework principal de desarrollo
- **Firebase Data Connect**: Para la gestión de datos
- **Google Sign-In**: Sistema de autenticación

### Configuración de Desarrollo

#### Firebase Data Connect
La aplicación utiliza Firebase Data Connect con un conector por defecto. Para desarrollo local, se puede conectar al emulador usando el puerto 9399.

### Instalación
1. Clonar el repositorio
2. Ejecutar `flutter pub get`
3. Configurar Firebase según la documentación
4. Ejecutar la aplicación con `flutter run`