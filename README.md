# Lift.xto
 
App Flutter para llevar el seguimiento de tu rutina de gimnasio con **sobrecarga progresiva**, **peso corporal** e **IMC**. Toda la información se guarda **localmente con SQLite** vía `sqflite`.
 
## Características
 
- ✅ Rutina semanal precargada (Lunes a Sábado) con tu plan actual
- ✅ Editar / eliminar / agregar ejercicios en cualquier día (incluido Miércoles)
- ✅ Registro de peso (kg) × sets × reps por sesión
- ✅ Registro de duración (segundos) para planchas y cardio
- ✅ Gráfico de evolución por ejercicio con `fl_chart`
- ✅ Récord personal (PR) y resumen de sesiones
- ✅ Tracking de peso corporal con gráfico
- ✅ Calculadora de IMC con peso saludable recomendado
- ✅ Almacenamiento 100% local con SQLite
- ✅ Material 3 con paleta **azul marino** (seed `#1E3A8A`)
- ✅ Toggle **claro / oscuro / sistema** persistente con `SharedPreferences`
## Estructura
 
```
lib/
├── main.dart                       # Entry point + ValueListenableBuilder de tema
├── database/
│   ├── database_helper.dart        # SQLite singleton + CRUD
│   └── default_routine.dart        # Seed de tu rutina
├── models/
│   ├── exercise.dart
│   ├── exercise_log.dart
│   ├── body_weight_log.dart
│   └── user_profile.dart
├── screens/
│   ├── home_screen.dart            # Bottom navigation
│   ├── routine_screen.dart         # Vista de los 7 días
│   ├── day_exercises_screen.dart   # Ejercicios de un día
│   ├── add_edit_exercise_screen.dart
│   ├── exercise_detail_screen.dart # Historial + gráfico + PR
│   ├── progress_screen.dart        # Resumen de PRs
│   └── body_screen.dart            # Tabs: Peso corporal | IMC
├── widgets/
│   ├── log_entry_sheet.dart        # Bottom sheet para registrar peso
│   ├── body_weight_sheet.dart      # Bottom sheet para peso corporal
│   ├── profile_sheet.dart          # Bottom sheet del perfil
│   └── theme_toggle_button.dart    # Botón AppBar para alternar tema
└── utils/
    ├── constants.dart              # Días de la semana, tracking types
    ├── theme.dart                  # Material 3 theme (seed azul marino)
    └── theme_controller.dart       # ValueNotifier + persistencia del modo
```
 
## Setup
 
```bash
flutter create lift_xto
cd lift_xto
# Reemplazá pubspec.yaml y la carpeta lib/ con los archivos de este proyecto
flutter pub get
flutter run
```
 
### Nombre visible en el launcher
 
El `pubspec.yaml` define el package interno (`lift_xto`), pero el nombre que ve el usuario en el ícono de la app se configura aparte:
 
**Android** — `android/app/src/main/AndroidManifest.xml`:
```xml
<application android:label="Lift.xto" ...>
```
 
**iOS** — `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Lift.xto</string>
```
 
## Esquema SQLite
 
```sql
exercises (id, day_of_week, name, sets, reps_min, reps_max,
           duration_seconds_min, duration_seconds_max,
           tracking_type, order_index, notes)
 
exercise_logs (id, exercise_id, date, weight_kg, sets_completed,
               reps_completed, duration_seconds, notes)
 
body_weight_logs (id, date, weight_kg, notes)
 
user_profile (id, height_cm, age, gender)
```
 
Las foreign keys están activas (`PRAGMA foreign_keys = ON`), así que eliminar un ejercicio borra en cascada todo su historial. El archivo de la BD se llama `lift_xto.db`.
 
## Cómo funciona la sobrecarga progresiva
 
1. Tocá un día de la semana → tocá un ejercicio.
2. Pulsá **"Registrar"** y guardá peso × sets × reps de esa sesión.
3. La próxima vez, el formulario auto-rellena los valores anteriores como referencia.
4. La gráfica muestra la evolución y el card de **PR** marca tu récord absoluto.
## Cómo funciona el IMC
 
1. Pestaña **Cuerpo → IMC → Editar perfil** → ingresá estatura.
2. Registrá tu peso en la pestaña **Peso corporal**.
3. La pantalla calcula:
   - Tu IMC actual
   - Categoría (Bajo peso / Normal / Sobrepeso / Obesidad)
   - Rango de peso saludable para tu estatura (BMI 18.5–24.9)
## Tema claro / oscuro
 
El icono en la AppBar (esquina superior derecha en cualquier tab) cicla entre tres estados:
 
| Icono | Modo | Comportamiento |
|---|---|---|
| 🌗 `brightness_auto` | Sistema | Sigue al ajuste del SO |
| ☀️ `light_mode` | Claro | Forzado |
| 🌙 `dark_mode` | Oscuro | Forzado |
 
La preferencia se persiste en `SharedPreferences` (key `theme_mode`) y se aplica antes del primer frame para evitar parpadeos al iniciar.
 
## Notas técnicas
 
- **Sin BLoC ni Provider**: arquitectura simple con `FutureBuilder` + `setState` y un `ValueNotifier` global para el tema.
- `IndexedStack` mantiene el estado de cada tab del bottom navigation.
- `AutomaticKeepAliveClientMixin` en las sub-tabs de Cuerpo para no recargar al hacer swipe.
- Migrations preparadas: cuando incrementes `_dbVersion`, agregá la lógica en `onUpgrade`.
- Locale `es` inicializado en `main.dart` para `DateFormat`.