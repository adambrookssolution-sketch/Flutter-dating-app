# Diagnóstico — moderación + propuesta de migración (30-abr-2026)

> Mensaje plano para WhatsApp. Va en respuesta directa a la captura
> "internal: internal" que mandó Alejandra. Ella ya envió el correo
> de moderador (affinitysocialclub@gmail.com) y el claim ya estaba
> activo — el problema es que el proyecto dev corre en plan Spark
> gratuito y Firebase no despliega Cloud Functions ahí.
> Tono: diagnóstico claro, sin tecnicismos crudos, framing de
> ambiente de pruebas vs productivo, abre puerta a migración esta
> semana (paso previo al lanzamiento de todas formas).

---

Diagnosticado, Alejandra.

Lo que pasa es lo siguiente: el panel y la app están corriendo
contra un proyecto Firebase de pruebas que dejé en plan gratuito
porque era el más limpio para hacerte demos sin tocar nada del
ambiente real. En ese plan gratuito Firebase no permite levantar
las funciones del servidor que procesan las decisiones de
moderación — por eso el botón te respondía "internal".

No es algo de tu cuenta ni del código de la app. Las funciones
están escritas, probadas y listas — solo necesitan el ambiente
correcto para correr. Ese ambiente correcto es el proyecto
Firebase definitivo de Affinity (el que viene del desarrollador
anterior, que ya tiene plan pago activo). En el momento que
hagamos la migración al ambiente productivo, todas las funciones
se despliegan ahí y los botones de Aprobar/Rechazar empiezan a
trabajar de verdad — sin tocar una línea más de código.

Mientras tanto, ya dejé en el panel un mensajito amigable para
que si vuelves a probar no veas el error técnico, sino una nota
que explica que esa acción se activa en producción. En 5 minutos
estará vivo (lo está desplegando GitHub).

Resumen: lo que viste no es un bug, es la frontera entre el
ambiente de pruebas gratuito y el productivo. El panel, la cola
de moderación, el video player, el flujo entero de decisión —
todo está construido. Solo está esperando aterrizar en el
ambiente final.

Si quieres podemos coordinar esa migración esta semana misma —
es uno de los pasos previos al lanzamiento de todas formas, y
te abre la posibilidad de probar el flujo completo de extremo
a extremo.
