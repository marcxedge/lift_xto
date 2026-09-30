#!/usr/bin/env node
/**
 * Sube las miniaturas (images/) y GIFs (videos/) del dataset de ejercicios
 * a Firebase Storage, bajo exercise_catalog/images/ y exercise_catalog/gifs/
 * respectivamente — son las rutas que espera CatalogExerciseMedia
 * (lib/widgets/catalog_exercise_media.dart).
 *
 * Esta media es © Gym visual (https://gymvisual.com/), redistribuida acá
 * bajo tu propia responsabilidad/permiso — ver NOTICE.md del dataset
 * original (github.com/hasaneyldrm/exercises-dataset) antes de subirla.
 *
 * Uso:
 *   1. npm install firebase-admin   (una sola vez, en esta carpeta o en la
 *      raíz del proyecto — no hace falta agregarlo a pubspec.yaml, es sólo
 *      para este script, no para la app)
 *   2. Firebase Console → Configuración del proyecto → Cuentas de servicio
 *      → "Generar nueva clave privada" → guardá el JSON como
 *      scripts/serviceAccountKey.json (¡NO lo subas a git! agregalo a
 *      .gitignore si no está ya)
 *   3. node scripts/upload_exercise_media.js "C:/ruta/al/exercises-dataset-main"
 */
const fs = require("fs");
const path = require("path");

const datasetDir = process.argv[2];
if (!datasetDir) {
  console.error("Uso: node upload_exercise_media.js <ruta-al-dataset>");
  process.exit(1);
}

const serviceAccountPath = path.join(__dirname, "serviceAccountKey.json");
if (!fs.existsSync(serviceAccountPath)) {
  console.error(
    `No encontré ${serviceAccountPath}.\n` +
      "Generá una clave de cuenta de servicio en Firebase Console → " +
      "Configuración del proyecto → Cuentas de servicio → " +
      "Generar nueva clave privada, y guardala en esa ruta."
  );
  process.exit(1);
}

const admin = require("firebase-admin");
const serviceAccount = require(serviceAccountPath);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  storageBucket: "liftxto.firebasestorage.app",
});

const bucket = admin.storage().bucket();

async function uploadDir(localDir, remotePrefix, contentType) {
  const files = fs.readdirSync(localDir).filter((f) => !f.startsWith("."));
  console.log(`${localDir} → ${remotePrefix}/ (${files.length} archivos)`);

  let done = 0;
  const concurrency = 12;
  let cursor = 0;

  async function worker() {
    while (cursor < files.length) {
      const file = files[cursor++];
      const localPath = path.join(localDir, file);
      const remotePath = `${remotePrefix}/${file}`;
      await bucket.upload(localPath, {
        destination: remotePath,
        metadata: {
          contentType,
          cacheControl: "public, max-age=31536000, immutable",
        },
      });
      done++;
      if (done % 50 === 0 || done === files.length) {
        console.log(`  ${done}/${files.length}`);
      }
    }
  }

  await Promise.all(Array.from({ length: concurrency }, worker));
}

async function main() {
  await uploadDir(
    path.join(datasetDir, "images"),
    "exercise_catalog/images",
    "image/jpeg"
  );
  await uploadDir(
    path.join(datasetDir, "videos"),
    "exercise_catalog/gifs",
    "image/gif"
  );
  console.log("Listo.");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
