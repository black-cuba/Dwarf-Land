# Dwarf Land — Arquitectura técnica

## Objetivo

Mantener la simulación separada de la interfaz. Las reglas de supervivencia deben poder probarse sin cargar escenas ni depender de controles gráficos.

## Estructura por dominios

- `scripts/models/colonist.gd`: estado individual, necesidades, salud y condición de cada colono.
- `scripts/systems/inventory.gd`: cantidades, capacidad de almacenamiento y operaciones seguras del inventario.
- `scripts/systems/colony_simulation.gd`: reloj de colonia, avance horario, satisfacción de necesidades y alertas.\n- `scripts/models/work_order.gd`: orden de trabajo con prioridad, progreso y estado.
- `scripts/models/resource_node.gd`: fuente de recursos finita o renovable con reserva y regeneración.\n- `scripts/systems/work_scheduler.gd`: asignación de trabajos, prioridad, bonificación profesional y bloqueo por necesidades críticas.
- `scenes/`: presentación visual y navegación.
- `docs/`: diseño, arquitectura y decisiones técnicas.

## Reglas de simulación iniciales

- El reloj avanza una hora por paso de simulación.
- La colonia tiene exactamente dos niveles; el índice interno válido es 0 o 1.
- Hambre, sed y fatiga se calculan por colono.
- El consumo de agua y comida solo ocurre si existe inventario disponible.
- La capacidad del almacén limita la entrada de recursos.
- Las órdenes reservan recursos de una fuente física; no generan recursos ilimitados.
- Las fuentes renovables recuperan existencias al comenzar un nuevo día; los depósitos minerales no se regeneran.
- Los colonos suspenden el trabajo cuando hambre, sed o fatiga alcanzan umbrales críticos.
- Cada profesión tiene un rendimiento mayor en sus tareas especializadas.
- La muerte de un colono no elimina su registro histórico.
- La interfaz no debe modificar directamente las necesidades ni el inventario: solicita acciones al sistema de simulación.

## Próximas capas

1. Trabajos y prioridades autónomas con selección de tareas válidas.
2. Construcción, habitaciones, camas y capacidad real de almacenamiento.
3. Cultivos, ciclos de crecimiento, cosecha y producción.
4. Minería, vetas, herramientas, desgaste y transporte entre niveles.
5. Temperatura ambiental, aislamiento, enfermedad y accidentes.
6. Persistencia local versionada y recuperación segura de partidas.
7. Modos Campaña, Supervivencia y Sandbox.
8. Pruebas automatizadas de reglas y validación de rendimiento en Android.

## Restricciones

- Sin servicios remotos, anuncios, analítica ni conexión obligatoria.
- Recursos y arte originales.
- No exportar APK durante el desarrollo. La exportación final requiere que el juego esté completo, validado y autorización expresa.
