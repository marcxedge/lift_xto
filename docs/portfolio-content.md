# Contenido para portafolio — Proyecto: Lift.xto

Contenido para **actualizar el proyecto Lift.xto que ya existe** en
`portafolio-mario-rodriguez` (agregado antes como segundo proyecto, junto a
"Comunicación aumentada para inclusión auditiva"), con las funcionalidades
nuevas que se sumaron desde la última actualización. Mismo esquema de
campos de siempre en `index.html` / `js/i18n.js`: `tag`, `title`, `date`,
`affiliation`, `cardTitle`, `description`, `point1-3`, `tags`,
`galleryTitle`, `shotNTitle` / `shotNDesc`.

Repo del proyecto: https://github.com/marcxedge/lift_xto

---

## Prompt para pegar en el chat que arma el portafolio

```
Necesito que actualices el proyecto Lift.xto que ya está agregado en mi
portafolio (portafolio-mario-rodriguez) — no es un proyecto nuevo, es el
mismo que ya existe, sólo cambió su contenido porque se le sumaron
funcionalidades.

Te paso el contenido actualizado (español e inglés) en el archivo adjunto
docs/portfolio-content.md del repo https://github.com/marcxedge/lift_xto:
reemplaza description, point1-3 y tags de ese proyecto con los de este
archivo, y agrega 2 capturas nuevas al final de su galería (shot13 y
shot14, con su title/desc) — las capturas existentes de la galería se
quedan igual, no hace falta rehacerlas.

Las 2 capturas nuevas están en lift_xto/docs/screenshots/
(sugerencia_progresion.png, resumen_wrapped.png) — cópialas a la misma
carpeta de assets donde están las demás capturas de este proyecto.

Actualiza en ambos idiomas (es/en) manteniendo el estilo y la estructura
HTML/JS existente, sin tocar el resto del portafolio.
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
con sobrecarga progresiva, mapa muscular, peso corporal, medidas corporales
e IMC. Incluye un catálogo de referencia de ~1300 ejercicios (con GIFs de
la técnica e instrucciones en español), una racha de constancia que sigue
la rutina real del usuario, y una capa de autorregulación propia: sugiere
el peso de la próxima sesión, avisa si un ejercicio se estancó, y genera un
resumen compartible tipo "Wrapped" con tus récords y totales — todo sobre
datos que la app ya tiene, sin modelos externos. Unidad de peso
configurable (kg/lb) con conversión automática en toda la app. Los datos se
guardan localmente en SQLite y se sincronizan en segundo plano con Firebase
(Firestore + Storage) mediante un patrón outbox, funcionando sin conexión y
trayendo automáticamente toda tu información al iniciar sesión en un
dispositivo nuevo. Arquitectura en capas (Repository + Observer) con
inyección de dependencias, validación de datos centralizada, diseño
responsive (teléfonos chicos y tablets) y hardening de seguridad en la
build de Android.
```

**point1** (con `<strong>` permitido, como en el proyecto existente):
```
<strong>Flutter/Dart</strong> con <strong>SQLite local</strong> + sincronización <strong>offline-first</strong> contra Firebase Firestore/Storage (patrón outbox, resolución de conflictos por última escritura).
```

**point2**:
```
Catálogo de referencia de <strong>~1300 ejercicios</strong> con instrucciones en español y GIFs de la técnica servidos bajo demanda desde Firebase Storage, más un <strong>mapa muscular interactivo</strong> y una <strong>racha de constancia</strong> calculada contra la rutina real del usuario.
```

**point3**:
```
Capa de autorregulación propia sobre tu propio historial — <strong>sugerencia de sobrecarga progresiva</strong>, <strong>alerta de estancamiento</strong> y un <strong>resumen compartible</strong> con tus totales y récords, sin IA ni servicios externos — más arquitectura <strong>Repository + Observer</strong> (ChangeNotifier + provider), autenticación con <strong>Google Sign-In o email/contraseña</strong>, unidad de peso <strong>kg/lb</strong> configurable, diseño <strong>responsive</strong> y build de Android endurecida.
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

### Galería (shot1 – shot14)

| # | Archivo | Title | Desc |
|---|---------|-------|------|
| 1 | `login.png` | **Inicio de sesión** | Login con Google o email/contraseña (con toggle de mostrar/ocultar contraseña) — habilita la sincronización con Firebase y el acceso multi-dispositivo. |
| 2 | `perfil_configuracion.png` | **Perfil obligatorio** | La primera vez que inicias sesión, la app pide nombre, apellido, estatura y fecha de nacimiento antes de dejarte entrar — la edad se calcula sola, sin pedirla directamente. |
| 3 | `rutina_semanal.png` | **Rutina semanal + racha** | Vista principal con los 7 días de la semana, el día actual destacado, y una racha 🔥 de días consecutivos entrenados según lo programado — los días libres no la cortan. |
| 4 | `dia_ejercicios.png` | **Ejercicios del día** | Listado de ejercicios de un día puntual, con series/repeticiones objetivo y el grupo muscular elegido manualmente al crear cada ejercicio. |
| 5 | `detalle_ejercicio.png` | **Detalle y progresión** | Historial de sesiones, récord personal (PR) y gráfico de evolución del peso levantado a lo largo del tiempo para ese ejercicio. |
| 6 | `progreso_volumen.png` | **Volumen y 1RM estimado** | El mismo gráfico admite cambiar la métrica a volumen total o 1RM estimado (fórmula de Epley) — revela progreso real cuando el peso se mantiene pero las repeticiones suben. |
| 7 | `progreso_prs.png` | **Resumen de progreso** | Vista consolidada de récords personales por ejercicio, actualizada al instante gracias a la arquitectura reactiva (Repository + Observer) — sin necesidad de recargar la app. |
| 8 | `mapa_muscular.png` | **Mapa muscular** | Visualización del volumen entrenado por grupo muscular en los últimos días, calculado a partir de la categorización elegida en cada ejercicio. |
| 9 | `catalogo_busqueda.png` | **Catálogo de ejercicios** | Búsqueda y filtro por músculo sobre un catálogo de referencia de ~1300 ejercicios, con nombre traducido a español y miniatura de la técnica. |
| 10 | `catalogo_detalle.png` | **Ficha del ejercicio** | Cada ejercicio del catálogo trae un GIF animado de la técnica correcta e instrucciones numeradas en español — se puede usar para precargar nombre y músculo al crear un ejercicio propio. |
| 11 | `cuerpo.png` | **Perfil, peso e IMC** | Pantalla unificada de perfil, peso corporal e Índice de Masa Corporal, con escala visual y rango de peso saludable recomendado para tu estatura. |
| 12 | `medidas_corporales.png` | **Medidas corporales** | Cintura, pecho, cadera, bíceps, muslo, pantorrilla y cuello, con gráfico de evolución por zona — complementa el peso/IMC con composición corporal aproximada. |
| 13 | `sugerencia_progresion.png` | **Sugerencia de progresión** | Al registrar una sesión, la app sugiere el peso/reps de la próxima según si llegaste al techo o piso de tu rango objetivo — autorregulación simple sobre tu propio historial. |
| 14 | `resumen_wrapped.png` | **Tu resumen, compartible** | Kg totales levantados, racha máxima histórica, músculo más trabajado y PRs destacados en una tarjeta que se comparte como imagen con un toque. |

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
overload, a muscle map, body weight, body measurements, and BMI. Includes a
reference catalog of ~1300 exercises (with technique GIFs and Spanish
instructions), a consistency streak that follows the user's actual
routine, and a self-coaching layer: it suggests next session's weight,
flags exercises that stalled, and generates a shareable "Wrapped"-style
summary with your totals and records — all from data the app already has,
no external models. Configurable weight unit (kg/lb) with automatic
conversion throughout the app. Data is stored locally in SQLite and synced
in the background with Firebase (Firestore + Storage) using an outbox
pattern, working fully offline and automatically pulling your data when
signing in on a new device. Layered architecture (Repository + Observer)
with dependency injection, centralized input validation, responsive design
(small phones and tablets), and Android security hardening in the release
build.
```

**point1**:
```
<strong>Flutter/Dart</strong> with <strong>local SQLite</strong> plus <strong>offline-first</strong> sync against Firebase Firestore/Storage (outbox pattern, last-write-wins conflict resolution).
```

**point2**:
```
Reference catalog of <strong>~1300 exercises</strong> with Spanish instructions and technique GIFs served on demand from Firebase Storage, plus an <strong>interactive muscle map</strong> and a <strong>consistency streak</strong> computed against the user's actual routine.
```

**point3**:
```
A self-coaching layer built on your own history — <strong>progressive overload suggestions</strong>, a <strong>plateau alert</strong>, and a <strong>shareable summary</strong> of your totals and records, no AI or external services — plus <strong>Repository + Observer</strong> architecture (ChangeNotifier + provider), <strong>Google Sign-In or email/password</strong> authentication, configurable <strong>kg/lb</strong> weight unit, responsive design, and a hardened Android release build.
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

### Gallery (shot1 – shot14)

| # | File | Title | Desc |
|---|------|-------|------|
| 1 | `login.png` | **Sign in** | Sign in with Google or email/password (with a show/hide password toggle) — enables Firebase sync and multi-device access. |
| 2 | `perfil_configuracion.png` | **Mandatory profile** | The first time you sign in, the app asks for first/last name, height, and birth date before letting you in — age is computed automatically, never asked directly. |
| 3 | `rutina_semanal.png` | **Weekly routine + streak** | Main view with all 7 days of the week, today highlighted, and a 🔥 streak of consecutive days trained according to the schedule — rest days don't break it. |
| 4 | `dia_ejercicios.png` | **Day's exercises** | Exercise list for a given day, with target sets/reps and the muscle group picked by hand when the exercise was created. |
| 5 | `detalle_ejercicio.png` | **Exercise detail & progression** | Session history, personal record (PR), and a chart showing the weight progression over time for that exercise. |
| 6 | `progreso_volumen.png` | **Volume & estimated 1RM** | The same chart can switch to total volume or estimated 1RM (Epley formula) — reveals real progress when weight stays flat but reps go up. |
| 7 | `progreso_prs.png` | **Progress summary** | Consolidated view of personal records per exercise, updated instantly thanks to the reactive Repository + Observer architecture — no app restart needed. |
| 8 | `mapa_muscular.png` | **Muscle map** | Visualization of trained volume per muscle group over the last few days, computed from the categorization chosen for each exercise. |
| 9 | `catalogo_busqueda.png` | **Exercise catalog** | Search and filter by muscle over a reference catalog of ~1300 exercises, with names translated to Spanish and a technique thumbnail. |
| 10 | `catalogo_detalle.png` | **Exercise detail** | Every catalog exercise ships an animated technique GIF and numbered Spanish instructions — can be used to prefill name and muscle group when creating your own exercise. |
| 11 | `cuerpo.png` | **Profile, weight & BMI** | Unified profile, body weight, and Body Mass Index screen, with a visual scale and the recommended healthy weight range for your height. |
| 12 | `medidas_corporales.png` | **Body measurements** | Waist, chest, hips, biceps, thigh, calf, and neck, with an evolution chart per area — complements weight/BMI with approximate body composition. |
| 13 | `sugerencia_progresion.png` | **Progression suggestion** | When logging a session, the app suggests next time's weight/reps based on whether you hit the top or bottom of your target rep range — simple self-regulation over your own history. |
| 14 | `resumen_wrapped.png` | **Your shareable summary** | Total kg lifted, longest streak ever, most-trained muscle, and standout PRs in one card you can share as an image with a tap. |

---

## Recursos

- **Repositorio**: https://github.com/marcxedge/lift_xto
- **Capturas nuevas de esta actualización**: `lift_xto/docs/screenshots/sugerencia_progresion.png`
  y `lift_xto/docs/screenshots/resumen_wrapped.png` — copiarlas a la misma carpeta de
  assets donde ya están las 12 capturas anteriores del proyecto (p. ej. `assets/img/lift-xto/`).
