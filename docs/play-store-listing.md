# Ficha de Play Store — Lift.xto

Todo lo necesario para completar la ficha de Play Console (`io.liftxto.app`).
Paquete de id: `io.liftxto.app`.

---

## 1. Textos

### Nombre de la aplicación (máx. 30 caracteres)

```
Lift.xto
```
8/30 — no hace falta cambiarlo, ya está bien.

### Descripción breve (máx. 80 caracteres)

```
Sobrecarga progresiva, mapa muscular y sincronización en la nube para tu gym
```
76/80.

### Descripción completa (máx. 4000 caracteres)

```
Lift.xto es tu compañero de entrenamiento para gimnasio: llevá tu rutina semanal, registrá cada serie y repetición, y mirá tu progreso reflejado en gráficos y récords personales — sin depender de una planilla ni de la memoria.

LO QUE HACE DIFERENTE A LIFT.XTO

🏋️ Sobrecarga progresiva real
Registrá peso, series y repeticiones de cada sesión. La app sugiere automáticamente el peso y las repeticiones de tu próxima sesión según si llegaste al techo o al piso de tu rango objetivo — autorregulación simple, sin IA ni suscripciones.

📊 Gráficos que muestran progreso real
Cambiá entre peso levantado, volumen total o 1RM estimado (fórmula de Epley) para cada ejercicio — el volumen y el 1RM revelan progreso que el peso solo no muestra cuando las repeticiones suben.

🔥 Racha de constancia
Seguí tus días consecutivos entrenados según tu propia rutina — los días libres no la cortan.

⚠️ Alerta de estancamiento
Si varios ejercicios dejan de mejorar, la app te avisa para que consideres una semana de descarga.

💪 Mapa muscular visual
Visualizá qué grupos musculares trabajaste más según el volumen de tus últimas sesiones.

📚 Catálogo de ~1300 ejercicios
Buscá por nombre o músculo, mirá instrucciones en español y un GIF de la técnica correcta.

⚖️ Peso corporal, medidas e IMC
Registrá tu peso, cintura, pecho, cadera, bíceps, muslo, pantorrilla y cuello, con gráfico de evolución y rango de peso saludable según tu estatura.

🎉 Tu resumen, compartible
Una tarjeta con tus kg totales levantados, racha máxima y récords destacados que podés compartir con un toque.

⚙️ A tu manera
Elegí kg o lb en toda la app, y tema claro, oscuro o según tu sistema.

PRIVACIDAD PRIMERO
Tus datos se guardan en tu dispositivo y se sincronizan en segundo plano con tu cuenta — nada de anuncios, nada de rastreo, nada de analítica de terceros. Iniciá sesión en un dispositivo nuevo y toda tu información te espera ahí.

Lift.xto funciona sin conexión salvo para iniciar sesión la primera vez — perfecto para el gimnasio, con o sin señal.
```

---

## 2. Recursos gráficos

| Recurso | Especificación pedida | Archivo listo | Estado |
|---|---|---|---|
| Ícono de la app | PNG/JPEG, máx. 1 MB, 512×512 px | `docs/playstore/icon_512.png` | ✅ Generado (12 KB) |
| Gráfico de funciones | PNG/JPEG, máx. 15 MB, 1024×500 px | `docs/playstore/feature_graphic_1024x500.png` | ✅ Generado (23 KB) |
| Capturas de teléfono | 2 a 8, PNG/JPEG, máx. 8 MB c/u, lados entre 320–3840 px | ver tabla abajo | ✅ Ya existían, elegidas 8 de 14 |

### Capturas de teléfono — orden recomendado para subir

Las primeras son las que más se ven en el listado, por eso van las más vistosas primero.

| # | Archivo | Por qué esta |
|---|---------|--------------|
| 1 | `docs/screenshots/rutina_semanal.png` | Pantalla principal, con racha 🔥 |
| 2 | `docs/screenshots/resumen_wrapped.png` | El diferenciador más visual de la app |
| 3 | `docs/screenshots/sugerencia_progresion.png` | Muestra la "inteligencia" de la app |
| 4 | `docs/screenshots/progreso_volumen.png` | Gráfico con selector de métrica |
| 5 | `docs/screenshots/mapa_muscular.png` | Visualización por grupo muscular |
| 6 | `docs/screenshots/catalogo_detalle.png` | GIF de técnica + instrucciones |
| 7 | `docs/screenshots/cuerpo.png` | Peso corporal + IMC |
| 8 | `docs/screenshots/medidas_corporales.png` | Composición corporal |

**Nota sobre la relación de aspecto:** estas capturas están en 1440×3120
(~2.17:1), la resolución nativa del emulador Pixel usado para generarlas.
Play Console pide que cada lado mida entre 320 y 3840 px (lo cumplen) y
describe el aspecto como "16:9 o 9:16" en el texto de ayuda, pero en la
práctica acepta la resolución nativa de teléfonos reales como este. Debería
subir sin problema; si Play Console rechaza alguna en particular, hay que
recortarla a mano revisando que no se corte contenido importante — avisar
para hacerlo con cuidado en esa captura puntual.

---

## 3. Otros campos que vas a encontrar en la ficha

| Campo | Valor sugerido |
|---|---|
| Categoría | Salud y forma física |
| Correo de contacto | marior8488@gmail.com |
| Sitio web (opcional) | https://github.com/marcxedge/lift_xto |
| Política de privacidad (obligatoria) | https://marcxedge.github.io/lift_xto/privacy-policy.html |
| Anuncios | La app no tiene |
| Compras dentro de la app | La app no tiene |

### Clasificación de contenido

Al completar el cuestionario de IARC, la app no tiene violencia, contenido
sexual, lenguaje ofensivo, apuestas ni interacción entre usuarios (no hay
chat ni contenido generado por otros usuarios) — debería calificar para la
clasificación más baja disponible ("Para todos" / PEGI 3 equivalente).

### Público objetivo y contenido

No está dirigida específicamente a niños. Recopila datos de salud (peso,
medidas, rutina) ingresados voluntariamente por el usuario — ver el detalle
completo en la política de privacidad enlazada arriba, que también cubre la
sección "Seguridad de los datos" del formulario de Play Console (qué se
recopila, para qué, con quién se comparte, cómo se elimina).

---

## 4. Checklist antes de enviar a revisión

- [ ] Pegar nombre, descripción breve y completa (sección 1)
- [ ] Subir ícono 512×512 (`docs/playstore/icon_512.png`)
- [ ] Subir gráfico de funciones 1024×500 (`docs/playstore/feature_graphic_1024x500.png`)
- [ ] Subir las 8 capturas de teléfono en el orden sugerido
- [ ] Completar categoría, contacto y política de privacidad (sección 3)
- [ ] Completar el cuestionario de clasificación de contenido
- [ ] Completar la sección "Seguridad de los datos" usando `docs/privacy-policy.md` como referencia
- [ ] Subir el `.aab` firmado — **pendiente**: la build de release todavía usa la keystore de debug como placeholder (`android/app/build.gradle.kts`), hace falta generar una keystore propia antes de publicar de verdad
