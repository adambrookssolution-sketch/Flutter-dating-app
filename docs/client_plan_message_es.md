# Mensaje de plan de trabajo — después de probar el APK de la agencia

---

**Versión WhatsApp (recomendada):**

---

Hola María,

Gracias por el APK y los diseños. Ya probé la versión de la agencia con calma y efectivamente tiene avances importantes sobre lo que yo tenía: verificación por email al registrarse, flujo de chat funcionando, gestión de trips, edición de perfil. Muy buen progreso de su parte.

Después de ver lo que ya existe y lo que usted me pidió agregar, le propongo un **plan de entregables modulares** en lugar de tocar la base de la agencia. Así evitamos completamente el riesgo de que mi trabajo y el de la agencia se pisen, y usted mantiene el control total sobre qué se integra y cuándo.

## Lo que le entregaría

**Componentes UI nuevos** (se pegan encima de la versión actual sin reescribir nada):
1. Botón de filtros tipo piña dorada, fijo arriba
2. Campanita de notificaciones en la pantalla de Perfil
3. Botones fijos abajo en el feed (Start Conversation + Filters) con lógica para saber qué pareja está visible
4. Campo de filtro por País
5. Pantalla de filtros completa con Travel Match integrado (según el diseño que me mandó)

**Correcciones y configuraciones** (cambios puntuales, no de arquitectura):
6. Activación de Google Sign-In (configuración de Firebase + OAuth)
7. Plantilla del correo de recuperación para que no llegue a spam
8. Autocompletado de Google Places (registro + perfil)
9. Filtro de geolocalización mínimo 5 km
10. Filtros independientes por sesión de usuario
11. Segmentación correcta de idiomas ES/EN
12. Flujo completo de requests de mensajes revisado y ajustado

**Extra consultado:** filtro de país dentro del feed — **sí es viable y lo incluyo** como parte del punto 4.

## Cómo lo entrego

Cada componente lo entrego como un archivo Dart o widget independiente con:
- El código listo para pegar
- Una nota corta de "cómo se conecta a la versión actual" (máximo 2–3 líneas por componente)
- Una captura de pantalla mostrando cómo se ve ya integrado en mi entorno de prueba

De esa forma, **su equipo / la agencia puede integrarlo a su ritmo**, y mientras ellos siguen avanzando con su rama principal, yo no interfiero.

## Tiempos estimados

- Componentes UI (puntos 1–5): **4–6 días**
- Correcciones de configuración (puntos 6–12): **3–5 días** (muchos dependen de ajustes en Firebase Console que tomo como prioridad)

Total: **entre 7 y 11 días laborales** para tener todos los entregables listos para su revisión.

## Una sola cosa que le pediría

Para que mis componentes se integren de la forma más limpia posible en la versión de la agencia — sin pequeños conflictos de estilo, nombres de variables, o librerías — **la mejor forma sería poder acceder al código fuente actual**, aunque sea en modo lectura. Con el código a la vista puedo garantizar que cada widget y cada configuración que le entregue encaje perfectamente desde el primer momento, sin requerir ajustes posteriores por parte del equipo de la agencia.

Sé que probablemente el código está bajo acuerdos de confidencialidad con la agencia, así que si no es viable compartirlo, no hay problema: puedo avanzar igual trabajando únicamente con el APK y los diseños. Solo que en ese caso es muy probable que al momento de integrar mis componentes aparezcan pequeños ajustes finales (estilo de código, naming, dependencias) que tomarán uno o dos días extra de trabajo conjunto con la agencia.

**En resumen: con código fuente, la integración es inmediata; sin código fuente, funciona igual pero con un ciclo corto de ajustes al final.** Le dejo a usted la decisión de cuál camino prefiere.

Quedo pendiente de su visto bueno para empezar con este plan.

Saludos,
Gabriel

---

**Versión larga (email formal, si prefiere enviarlo por correo):**

Incluye lo anterior más:

- Detalle por componente: qué hace, qué archivos toca, qué NO toca
- Checklist de aceptación por cada entrega
- Política de revisiones (cuántas rondas sin costo adicional)
- Política de compatibilidad (si la agencia cambia algo después, cómo se maneja)

*(Si quiere esta versión formal, me avisa y la extiendo)*
