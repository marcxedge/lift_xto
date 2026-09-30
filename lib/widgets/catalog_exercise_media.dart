import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

/// Miniatura o GIF animado de un ejercicio del catálogo, servido desde
/// Firebase Storage (`exercise_catalog/images/*` y `exercise_catalog/gifs/*`
/// — ver `scripts/upload_exercise_media.js`). El texto del catálogo
/// (`assets/data/exercise_catalog.json`) se empaqueta con la app y siempre
/// está disponible; la media es pesada (~140MB en total) así que se sirve
/// bajo demanda y se cachea localmente con `cached_network_image`.
///
/// Si Storage no está configurado, el archivo todavía no se subió, o no hay
/// conexión, se degrada a un ícono — nunca rompe la pantalla que lo usa.
class CatalogExerciseMedia extends StatelessWidget {
  const CatalogExerciseMedia({
    super.key,
    required this.fileName,
    this.animated = false,
    this.fit = BoxFit.cover,
  });

  /// Nombre de archivo tal como viene en el catálogo (`image` o `gif` de
  /// [CatalogExercise]), ej. `"0001-2gPfomN.jpg"`.
  final String? fileName;

  /// `true` para pedir el GIF animado (`exercise_catalog/gifs/`), `false`
  /// para la miniatura estática (`exercise_catalog/images/`).
  final bool animated;

  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final name = fileName;
    if (name == null) return _placeholder(context);

    final path = animated
        ? 'exercise_catalog/gifs/$name'
        : 'exercise_catalog/images/$name';

    return FutureBuilder<String>(
      future: FirebaseStorage.instance.ref(path).getDownloadURL(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return _loading(context);
        }
        if (snap.hasError || !snap.hasData) {
          return _placeholder(context);
        }
        return CachedNetworkImage(
          imageUrl: snap.data!,
          fit: fit,
          placeholder: (_, __) => _loading(context),
          errorWidget: (_, __, ___) => _placeholder(context),
        );
      },
    );
  }

  Widget _loading(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.fitness_center,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
      ),
    );
  }
}
