# Corrección + APK descargable + respuesta a las observaciones

Hola Alejandra,

Disculpa la confusión — el link que te compartí
(`affinity-dating-app-cf807.web.app`) es el **panel de moderación** que
ya conoces; ahí solo se ve la Cola de verificación porque ese sitio es
para el admin. La aplicación móvil no se puede revisar desde ahí.

Lo correcto es probar el **APK** directamente en un Android. He
arreglado el pipeline de compilación (la cuota de artefactos de GitHub
se había saturado) y ahora el APK se publica en una URL pública estable
que se refresca con cada cambio:

## 📱 Descarga del APK
```
https://firebasestorage.googleapis.com/v0/b/affinity-dating-app-cf807.firebasestorage.app/o/public-apk%2Fapp-debug.apk?alt=media&token=affinity-apk-7f3c8d92
```

**Instalación**: abre la URL desde Chrome en el Android → "Descargar" →
abrir el archivo `.apk` → "Instalar". Si el sistema te pide permiso para
"instalar aplicaciones desconocidas", actívalo solo para Chrome (es
normal con APK debug).

Este link **no cambia** entre versiones — cada vez que publiquemos un
nuevo cambio, el mismo URL devolverá la build más reciente. No hace
falta que te lo reenviemos.

---

## Cambios listos para revisar en este APK

### 1. Separación "Lo que los representa" ↔ "Lo que están buscando"
- **Perfil**: bloque "SELECCIONA LO QUE LOS REPRESENTA" con 5
  sub-secciones (Identidad Ella/Él, Rol Ella/Él, Tipo de interacción,
  Experiencia, Intereses).
- **Filtros del feed**: bloque "BUSCANDO" con las mismas 5 sub-secciones
  más Buscando Unicornio / Buscando Toro. El algoritmo del feed ya
  compara estas selecciones contra los campos del perfil de la otra
  pareja.

### 2. Mensajes de error específicos en el registro / inicio de sesión
El genérico "Error al registrarse" se reemplazó por mensajes
específicos: correo ya registrado, contraseña débil, credencial
inválida, demasiados intentos, sin red, etc.

---

## Respuesta a tus observaciones del 14/05

### Apple Sign-In — agencia siguió todo pero sigue fallando
Necesito revisar directamente. Por favor compárteme:
1. **Acceso a Apple Developer** (App Manager o superior) para el
   identificador del Service ID — necesito verificar la Return URL
   configurada.
2. **Captura del error exacto** que sale en el iPhone al pulsar
   "Continuar con Apple" — el mensaje + el código si aparece.

Si la agencia confirmó textualmente "siguió todo", la causa más
probable es un Return URL mal escrito o un Key ID que ya expiró. Lo
puedo confirmar en 5 minutos con el acceso.

### Google Sign-In — falló en el APK de ayer
La causa más probable es que el **SHA-1 del keystore con que se firma
la APK** no está registrado como huella OAuth en el proyecto Firebase
(`affinity-dating-app-cf807`). El APK que estás descargando ahora se
firma en GitHub Actions con un keystore distinto al de tu máquina, lo
cual rompe Google Sign-In.

Voy a confirmar/agregar el SHA-1 correcto en Firebase Console hoy
mismo y publicaré un APK con Google Sign-In funcionando.

### Mensajes / barra de búsqueda en chat
Anotado. Lo incluyo en el siguiente sprint (búsqueda por nombre de la
pareja en la lista de conversaciones).

### Feed por idioma de la app
Anotado. Cada pareja ya guarda el idioma con el que se registró
(`couples.language`); voy a usar ese campo para sesgar el feed cuando
el usuario cambie el idioma de la app.

### Selector de idioma dentro de la app
Anotado — añadiré un selector en la pantalla de Ajustes para que el
usuario pueda cambiar el idioma sin depender del idioma del sistema
operativo.

---

Quedo atento a tu confirmación + accesos para Apple Sign-In.
