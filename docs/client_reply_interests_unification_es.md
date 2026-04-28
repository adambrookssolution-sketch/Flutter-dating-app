# Respuesta a la unificación interests + Open to Unicorn/Bull

> Mensaje de Alejandra del 29-abr definiendo:
>   - Renombrado "Distintivos de pareja" → "Intereses de la pareja"
>   - Agrupación visual de interests en 3 bloques (Tipo / Forma /
>     Intereses libres)
>   - Backend único: interests: [] sin separar
>   - Nueva sección "Apertura de la pareja" con dos toggles:
>     openToUnicorn / openToBull
>   - Filtros deben usar EXACTAMENTE los mismos valores
>
> El mensaje cerró con "Coméntame tu criterio" — primer test real
> del rol de partner que ella misma me invitó a tomar el día
> anterior. La respuesta tiene que aceptar todo lo que pide y al
> mismo tiempo aportar valor sin parecer que estoy buscando
> aprobación: una observación de fondo (Open to Unicorn/Bull
> impacta el modelo de matching) + una propuesta técnica concreta
> (manera limpia de mantener UI agrupada con backend plano).

---

Hola Alejandra,

Me parece muy buena observación, y de hecho el principio que mencionas — registro, perfil y filtros usando exactamente la misma estructura — es justo lo que hace que el matching funcione bien o se rompa en silencio. Lo aplico tal cual lo describiste, paso por paso.

Te confirmo los siete puntos uno por uno:

1. Renombrado **"Distintivos de pareja" → "Intereses de la pareja"**, con el subtexto que pasaste, listo.

2. La agrupación visual en tres bloques (Tipo de interacción / Forma de experiencia / Intereses) la armo en UI con tres secciones tituladas, pero compartiendo el mismo control de selección. Visualmente queda claro y ordenado.

3. Backend único en `interests: []`. Para mantener la agrupación visual sin dependencia del orden en que se guardó el array, voy a dejar la definición de qué chip pertenece a qué bloque en una constante del lado del cliente — así el día de mañana podemos reordenar los grupos sin tocar la base de datos. Es una decisión técnica que no afecta el modelo que pediste, solo lo deja más limpio.

4. Sección **"Apertura de la pareja"** con su subtexto, debajo de Intereses, listo.

5. Toggles deslizables (no checkboxes) para Open to Unicorn (ella) y Open to Bull (él), con estados ON/OFF claros. Aplico el mismo control en perfil y en filtros para que se vea idéntico en los tres lados.

6. Campos booleanos independientes `openToUnicorn` y `openToBull` fuera de `interests`, exactamente como lo planteaste.

7. Filtros alineados con los mismos valores de `interests` y los dos toggles de apertura agregados.

Una observación de fondo, ya que me pides criterio:

Open to Unicorn / Open to Bull es un dato que naturalmente sugiere también un modelo de matching pareja-individuo, no solo pareja-pareja. Como ahorita la app está construida sobre el principio de "pareja como entidad única", mi sugerencia es que en esta primera versión usemos esos campos sólo para mostrar y para filtrar (cuando una pareja A filtra "openToUnicorn", ve parejas B que también tienen ese flag activo). Dejar el matching propiamente dicho con terceros individuales para una fase posterior nos evita tocar la lógica del feed ahora y nos deja la puerta abierta para diseñarlo bien cuando llegue el momento. Si tu visión ya contempla matching directo con individuos desde el inicio, dímelo y lo armamos así, solo que es una decisión que conviene tomar con calma porque cambia varias cosas atrás.

Sobre la migración: para la data ya existente que usa el campo `interests` como CSV de la primera versión, mi script de migración (que ya tengo escrito y probado) lo convierte a array sin perder nada. Y si la agencia trae su fase 2 con un nombre distinto para esta sección, la capa de adaptador que tengo en el modelo de Couple acepta ambas formas — quedó pensada justamente para escenarios así.

Tiempo de implementación: lo tengo listo en 1–2 días, con capturas para que lo valides antes de que cierre la semana.

Cualquier matiz que quieras ajustar de mi observación, dime y vamos.

Saludos,
Gabriel
