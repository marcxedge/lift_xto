---
title: Política de privacidad de Lift.xto
---

# Política de privacidad de Lift.xto

**Última actualización: 2 de octubre de 2026**

Esta política explica qué datos recopila la aplicación **Lift.xto**
(`io.liftxto.app`), cómo se usan y cómo puedes eliminarlos. Si tienes
dudas sobre esta política, puedes escribir a marior8488@gmail.com.

## 1. Quién trata tus datos

Lift.xto es desarrollada y publicada por Mario Rodríguez ("nosotros").
No vendemos tus datos ni los compartimos con terceros con fines
publicitarios. La app no muestra anuncios y no usa herramientas de
analítica ni de rastreo.

## 2. Qué datos recopilamos

### 2.1 Datos de cuenta

Para usar la app necesitas iniciar sesión, con una de estas opciones:

- **Google Sign-In**: recibimos tu nombre, correo electrónico y foto de
  perfil asociados a tu cuenta de Google.
- **Correo y contraseña**: recibimos el correo que ingreses. La
  contraseña nunca llega a nuestros servidores — la gestiona directamente
  Firebase Authentication (Google) de forma cifrada.

### 2.2 Datos de perfil (los ingresas tú)

Nombre, apellido, estatura, fecha de nacimiento y sexo (opcional). La
edad se calcula a partir de la fecha de nacimiento, nunca se pide
directamente.

### 2.3 Datos de entrenamiento y salud (los ingresas tú)

- Tu rutina: ejercicios, día de la semana, series/repeticiones objetivo,
  grupo muscular.
- Tus registros de entrenamiento: peso levantado, series, repeticiones,
  duración y fecha de cada sesión.
- Peso corporal y medidas corporales (cintura, pecho, cadera, bíceps,
  muslo, pantorrilla, cuello) que registres, con su fecha.

Estos datos los proporcionas voluntariamente al usar la app; Lift.xto no
los obtiene de ninguna otra fuente (no se conecta a básculas, relojes
inteligentes ni servicios de salud de terceros).

### 2.4 Datos que NO recopilamos

No accedemos a tu cámara, micrófono, contactos, ubicación ni archivos del
dispositivo. No usamos identificadores publicitarios. No integramos
analítica de uso (Google Analytics, etc.) ni reportes de errores de
terceros.

## 3. Cómo se almacenan tus datos

- **En tu dispositivo**: todos tus datos se guardan localmente en una
  base de datos SQLite — la app funciona sin conexión salvo para iniciar
  sesión la primera vez.
- **En la nube**: los mismos datos se sincronizan en segundo plano con
  **Firebase** (Firestore y Authentication, servicios de Google Cloud),
  para que puedas recuperarlos si cambias de dispositivo. Cada usuario
  sólo puede leer o escribir sus propios datos — las reglas de seguridad
  de Firestore lo impiden a nivel de servidor, aunque alguien conociera
  tu identificador de usuario.
- Firebase actúa como nuestro proveedor de infraestructura (procesador de
  datos) bajo sus propias condiciones de privacidad y seguridad:
  <https://firebase.google.com/support/privacy>.

## 4. Con quién compartimos tus datos

No compartimos, vendemos ni alquilamos tus datos a terceros. La única
empresa que procesa tus datos en nuestro nombre es **Google / Firebase**,
como proveedor de infraestructura de autenticación y base de datos.

Si usas el botón "Compartir" del resumen de entrenamiento, la imagen se
entrega al selector nativo de tu sistema operativo (Android) y eres tú
quien decide a qué app o persona enviarla — nosotros no intervenimos en
ese paso ni recibimos copia de lo que compartas.

## 5. Cuánto tiempo conservamos tus datos

Conservamos tus datos mientras tu cuenta exista. Si eliminas un registro
dentro de la app (un ejercicio, una sesión, un peso), se borra también de
la nube la próxima vez que sincronices.

## 6. Cómo eliminar tus datos o tu cuenta

Puedes pedirnos la eliminación completa de tu cuenta y de todos tus datos
(perfil, rutina, registros, peso y medidas) escribiendo a
marior8488@gmail.com desde el mismo correo asociado a tu cuenta.
Procesaremos la solicitud en un plazo razonable y te confirmaremos
cuando se complete.

## 7. Seguridad

- Las reglas de Firestore restringen el acceso a los datos de cada
  usuario a ese mismo usuario autenticado.
- Las copias de seguridad automáticas de Android están deshabilitadas
  para esta app, para que tus datos no terminen en un backup fuera de
  nuestro control.
- El build de producción de Android está minificado y ofuscado.

Ningún sistema es 100% infalible, pero tomamos medidas razonables para
proteger tu información.

## 8. Menores de edad

Lift.xto no está dirigida a menores de 13 años y no solicitamos a
sabiendas datos de menores de esa edad. Si crees que un menor nos
proporcionó datos, escríbenos para eliminarlos.

## 9. Cambios a esta política

Si cambiamos esta política, actualizaremos la fecha al inicio del
documento. Te recomendamos revisarla de vez en cuando.

## 10. Contacto

Para preguntas sobre esta política o tus datos: marior8488@gmail.com.

---

*Esta página vive en* <https://marcxedge.github.io/lift_xto/privacy-policy.html> *—
esa es la URL para pegar en Play Console cuando pida el link a la política de
privacidad.*
