# Respuesta sobre el panel web de moderación

---

**Versión WhatsApp (recomendada):**

---

Hola María, ¡perfecto! El panel web de moderación lo incluyo con gusto.

Le comento que ya tengo una base bastante avanzada del panel desde antes (pantalla de login, cola de moderación, pantalla de revisión de cada pareja, autenticación de moderadores con Firebase custom claims). Con lo que usted me describe, solo tengo que:

1. Refinar la lista de parejas en estado "pending_review"
2. Pulir los botones de Aprobar / Rechazar (con motivo obligatorio en el rechazo, como está en la spec)
3. Asegurar la automatización que menciona:
   - Al aprobar → el estado de la pareja pasa a "approved" automáticamente
   - En ese mismo instante la pareja aparece en el Couples Feed de todos los usuarios (sin ninguna acción manual extra)
   - Al rechazar → la pareja recibe notificación con el motivo y puede reintentar (máximo 2 intentos, al tercero queda bloqueada permanentemente, según lo que ya habíamos definido)
4. Desplegarlo en Firebase Hosting bajo una URL propia (ej: `affinity-admin.web.app`) para que solo usted y los moderadores autorizados puedan entrar

## Cómo funciona la automatización (resumen técnico)

Cuando una pareja termina el registro, su documento queda con `status: "pending_review"` en la base de datos. El Couples Feed solo muestra parejas con `status: "approved"`, así que automáticamente **no aparecen hasta que usted las apruebe desde el panel**.

Al hacer clic en "Aprobar" en el panel:
- El status cambia a `approved`
- Esa pareja aparece de inmediato en el feed de todos los demás usuarios
- Si tenía una solicitud de registro pendiente, queda marcada como verificada

No hay pasos intermedios ni sincronizaciones manuales — es todo en tiempo real.

## Tiempo estimado

Como ya tengo la base hecha, estimaría **2–3 días adicionales** sobre los 7–11 que le había indicado antes. El panel quedaría listo en paralelo con los demás componentes.

## Un detalle a confirmar

Cuando tenga un momento, si puede confirmarme si este panel web está dentro del alcance original que cerramos, o si lo manejamos como un módulo adicional, me orienta. Lo digo solo para mantener todo claro entre nosotros — por mi parte no hay problema en incluirlo, solo quiero que estemos alineados en el scope.

Empiezo esta semana con los primeros componentes y le mando capturas del panel en cuanto tenga la primera pantalla lista.

Saludos,
Gabriel
