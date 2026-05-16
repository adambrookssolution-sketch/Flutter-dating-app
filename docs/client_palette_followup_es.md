# Seguimiento — alineación de paleta exacta del Figma (29-abr-2026)

> Mensaje plano para WhatsApp. Va después del mensaje completo de
> estado + APK. Si aún no enviaste el mensaje completo, mejor mover
> este contenido al bloque 2 de aquel y enviar todo junto.
> Tono: nota técnica corta, sin grandilocuencia.

---

Hola Alejandra, una nota corta de seguimiento.

Después de mandarte el APK quise dar un paso más antes de cerrar el día.
Tomé el archivo de Figma que me compartiste y muestreé los colores
exactos que estabas usando — el borgoña principal, el borgoña oscuro
del degradado, los tonos de los botones. Resulta que la app estaba
corriendo con una aproximación bastante cercana pero no idéntica:
el borgoña real del Figma es #B01030 y el oscuro del degradado es
#580818, y nosotros teníamos #B31637 y #331837.

Lo que hice:

  • Reemplacé los 103 lugares del código donde el borgoña estaba
    escrito a mano, en 33 archivos (verificación, chat, perfil,
    suscripciones, filtros, viajes, bandeja de entrada, etc.).
  • Centralicé los colores de marca en un solo archivo
    (AppColors.primary, AppColors.primaryDark) — así el día que
    quieras mover la paleta cambiamos un solo lugar y se propaga.
  • Regeneré el ícono y el feature graphic con esos hex exactos.
  • Sincronicé el color de fondo del splash y el adaptive icon de
    Android para que cuadren con el degradado del Figma.

A simple vista no vas a notar una revolución, son tonos cercanos.
Pero ahora cuando alguien abra Affinity en el teléfono y al lado
abra tu Figma, los colores van a coincidir pixel-perfect. Es la
clase de detalle que el ojo no detecta consciente pero sí siente
cuando está mal.

Si te llega un nuevo APK del proyecto, ese ya trae estos cambios.
El anterior que te pasé hace un rato sigue siendo válido para
probar funcionalidad — esto es solo refinamiento visual.

Saludos,
Gabriel
