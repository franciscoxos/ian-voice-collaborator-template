# Integración con un Centro de Mando (CDM)

Módulo de acoplamiento opcional (Fase 2).

**No construir ahora.** Este módulo se activa cuando conectes este colaborador de voz a un Centro de Mando (CDM) que agrupe leads, actividades y reuniones en un solo sistema operativo del negocio.

## Qué hará

- Leer contactos desde las tablas del CDM (ej: `leads`, `clients`)
- Escribir resultados de llamadas en tablas de actividad y reuniones del CDM
- Registrarse en el CDM como un colaborador digital activo con configuración, permisos y métricas

## Convención sugerida

Las tablas del CDM receptor pueden seguir cualquier convención de nombres. Este módulo expone un adaptador configurable para mapear los campos de este colaborador de voz (`contacts`, `call_logs`) a los campos de tu CDM.

La integración se documenta en detalle cuando activemos la Fase 2.
