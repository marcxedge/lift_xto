# Contenido para portafolio — Proyecto: Lift.xto

Contenido listo para agregar como **segundo proyecto** en
`portafolio-mario-rodriguez`, siguiendo el mismo esquema de campos que ya
usa el proyecto actual ("Comunicación aumentada para inclusión auditiva")
en `index.html` / `js/i18n.js`: `tag`, `title`, `date`, `affiliation`,
`cardTitle`, `description`, `point1-3`, `tags`, `galleryTitle`,
`shotNTitle` / `shotNDesc`.

Repo del proyecto: https://github.com/marcxedge/lift_xto

---

## Prompt para pegar en el chat que arma el portafolio

```
Necesito que agregues un segundo proyecto a mi portafolio
(portafolio-mario-rodriguez), siguiendo exactamente el mismo esquema de
campos que ya usa el proyecto actual ("Comunicación aumentada para
inclusión auditiva") en index.html / js/i18n.js: tag, title, date,
affiliation, cardTitle, description, point1-3, tags, galleryTitle,
shotNTitle/shotNDesc para cada captura de una galería de 7 imágenes.

Te paso todo el contenido ya redactado (español e inglés) en el archivo
adjunto docs/portfolio-content.md del repo https://github.com/marcxedge/lift_xto.
Las 7 capturas están en lift_xto/docs/screenshots/*.png (login.png,
rutina_semanal.png, dia_ejercicios.png, detalle_ejercicio.png,
progreso_prs.png, mapa_muscular.png, cuerpo.png) — cópialas a la carpeta de
assets del portafolio y enlázalas en el mismo orden que aparecen en la
tabla de "Galería" del archivo.

Agrega el proyecto en ambos idiomas (es/en) manteniendo el estilo y la
estructura HTML/JS que ya existe para el primer proyecto, sin tocar el
contenido de ese proyecto existente.
```

---

## 🇪🇸 Español

**tag** (etiqueta sobre el título de sección):
```
Proyecto personal
```

**title** (título de la sección, corto/temático):
```
App de gimnasio con sincronización en la nube
```

**date**:
```
Abr 2026 — Sep 2026
```

**affiliation** (opcional — es un proyecto personal, no institucional; se puede omitir este campo o usar):
```
Proyecto personal, publicado en GitHub
```

**cardTitle** (nombre completo del proyecto):
```
Lift.xto — App Flutter de Seguimiento de Gimnasio con Sincronización Offline-First
```

**description**:
```
App Flutter multiplataforma para el seguimiento de entrenamiento de gimnasio
con sobrecarga progresiva, mapa muscular, peso corporal e IMC. Los datos se
guardan localmente en SQLite y se sincronizan en segundo plano con Firebase
(Firestore) mediante un patrón outbox, funcionando sin conexión y trayendo
automáticamente toda tu información al iniciar sesión en un dispositivo
nuevo. Arquitectura en capas (Repository + Observer) con inyección de
dependencias, validación de datos centralizada y hardening de seguridad en
la build de Android.
```

**point1** (con `<strong>` permitido, como en el proyecto existente):
```
<strong>Flutter/Dart</strong> con <strong>SQLite local</strong> + sincronización <strong>offline-first</strong> contra Firebase Firestore (patrón outbox, resolución de conflictos por última escritura).
```

**point2**:
```
Arquitectura <strong>Repository + Observer</strong> (ChangeNotifier + provider) que sincroniza el estado entre pantallas en tiempo real, y autenticación con <strong>Google Sign-In o email/contraseña</strong>.
```

**point3**:
```
Validación de datos centralizada, manejo de errores con feedback visible, mapa muscular interactivo por grupo trabajado, y build de Android endurecida (reglas de Firestore por usuario, backups deshabilitados, minificación/ofuscación en release).
```

**tags** (chips de tecnología):
```
Flutter
Dart
Firebase
SQLite
Provider
Material 3
Android
```

**galleryTitle**:
```
Capturas de la aplicación
```

### Galería (shot1 – shot7)

| # | Archivo | Title | Desc |
|---|---------|-------|------|
| 1 | `login.png` | **Inicio de sesión** | Login obligatorio con Google o email/contraseña — habilita la sincronización con Firebase y el acceso multi-dispositivo. |
| 2 | `rutina_semanal.png` | **Rutina semanal** | Vista principal con los 7 días de la semana, el día actual destacado y la cantidad de ejercicios cargados en cada uno. La rutina empieza vacía: cada usuario arma la suya desde cero. |
| 3 | `dia_ejercicios.png` | **Ejercicios del día** | Listado de ejercicios de un día puntual, con series/repeticiones objetivo y el grupo muscular elegido manualmente al crear cada ejercicio. |
| 4 | `detalle_ejercicio.png` | **Detalle y progresión** | Historial de sesiones, récord personal (PR) y gráfico de evolución del peso levantado a lo largo del tiempo para ese ejercicio. |
| 5 | `progreso_prs.png` | **Resumen de progreso** | Vista consolidada de récords personales por ejercicio, actualizada al instante gracias a la arquitectura reactiva (Repository + Observer) — sin necesidad de recargar la app. |
| 6 | `mapa_muscular.png` | **Mapa muscular** | Visualización del volumen entrenado por grupo muscular en los últimos días, calculado a partir de la categorización elegida en cada ejercicio. |
| 7 | `cuerpo.png` | **Perfil, peso e IMC** | Pantalla unificada de perfil, peso corporal e Índice de Masa Corporal, con escala visual y rango de peso saludable recomendado para tu estatura. |

---

## 🇬🇧 English

**tag**:
```
Personal project
```

**title**:
```
Gym app with cloud sync
```

**date**:
```
Apr 2026 — Sep 2026
```

**affiliation** (optional):
```
Personal project, published on GitHub
```

**cardTitle**:
```
Lift.xto — Flutter Gym Tracking App with Offline-First Sync
```

**description**:
```
Cross-platform Flutter app for tracking gym workouts with progressive
overload, a muscle map, body weight, and BMI. Data is stored locally in
SQLite and synced in the background with Firebase (Firestore) using an
outbox pattern, working fully offline and automatically pulling your data
when signing in on a new device. Layered architecture (Repository +
Observer) with dependency injection, centralized input validation, and
Android security hardening in the release build.
```

**point1**:
```
<strong>Flutter/Dart</strong> with <strong>local SQLite</strong> plus <strong>offline-first</strong> sync against Firebase Firestore (outbox pattern, last-write-wins conflict resolution).
```

**point2**:
```
<strong>Repository + Observer</strong> architecture (ChangeNotifier + provider) keeping every screen's state in sync in real time, with <strong>Google Sign-In or email/password</strong> authentication.
```

**point3**:
```
Centralized input validation, visible error feedback, an interactive muscle map by trained muscle group, and a hardened Android release build (per-user Firestore rules, backups disabled, minification/obfuscation enabled).
```

**tags**:
```
Flutter
Dart
Firebase
SQLite
Provider
Material 3
Android
```

**galleryTitle**:
```
App screenshots
```

### Gallery (shot1 – shot7)

| # | File | Title | Desc |
|---|------|-------|------|
| 1 | `login.png` | **Sign in** | Mandatory login with Google or email/password — enables Firebase sync and multi-device access. |
| 2 | `rutina_semanal.png` | **Weekly routine** | Main view with all 7 days of the week, today highlighted, and the exercise count loaded for each day. The routine starts empty: every user builds their own from scratch. |
| 3 | `dia_ejercicios.png` | **Day's exercises** | Exercise list for a given day, with target sets/reps and the muscle group picked by hand when the exercise was created. |
| 4 | `detalle_ejercicio.png` | **Exercise detail & progression** | Session history, personal record (PR), and a chart showing the weight progression over time for that exercise. |
| 5 | `progreso_prs.png` | **Progress summary** | Consolidated view of personal records per exercise, updated instantly thanks to the reactive Repository + Observer architecture — no app restart needed. |
| 6 | `mapa_muscular.png` | **Muscle map** | Visualization of trained volume per muscle group over the last few days, computed from the categorization chosen for each exercise. |
| 7 | `cuerpo.png` | **Profile, weight & BMI** | Unified profile, body weight, and Body Mass Index screen, with a visual scale and the recommended healthy weight range for your height. |

---

## Recursos

- **Repositorio**: https://github.com/marcxedge/lift_xto
- **Capturas** (ya generadas, listas para usar): `lift_xto/docs/screenshots/*.png`
  — copiar a la carpeta de assets del portafolio (p. ej. `assets/img/lift-xto/`).
