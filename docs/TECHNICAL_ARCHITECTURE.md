# Dwarf Land — Arquitectura técnica

## Objetivo

Separar las reglas de simulación de la interfaz. Los sistemas principales deben poder probarse sin cargar escenas ni depender de controles gráficos.

## Estructura por dominios

- `scripts/models/colonist.gd`: estado individual, necesidades, salud, temperatura corporal, profesión y posición.
- `scripts/models/resource_node.gd`: fuente de recursos finita o renovable, ubicación, reserva y regeneración.
- `scripts/models/work_order.gd`: orden de trabajo, prioridad, destino, progreso y estado.
- `scripts/systems/inventory.gd`: cantidades, capacidad de almacenamiento y operaciones seguras.
- `scripts/systems/navigation_grid.gd`: cuadrícula de dos niveles, celdas bloqueadas y búsqueda de rutas.
- `scripts/systems/work_scheduler.gd`: asignación por prioridad y especialidad, movimiento y ejecución de trabajos.
- `scripts/systems/colony_simulation.gd`: reloj, necesidades, recursos, inventario, producción y alertas.
- `scenes/`: presentación visual y navegación de interfaz.
- `tests/`: pruebas automatizadas de reglas de juego.
- `docs/`: diseño, arquitectura y criterios de aceptación.

## Reglas de simulación implementadas

- El reloj avanza una hora por paso de simulación.
- Solo existen dos niveles, identificados internamente como 0 y 1.
- La conexión vertical entre niveles está limitada al ascensor.
- Los colonos tienen hambre, sed, fatiga, salud y temperatura corporal.
- La comida y el agua se consumen del inventario; nunca aparecen automáticamente.
- Las fuentes de comida, agua y madera se regeneran diariamente hasta su capacidad.
- La cantera y la veta mineral tienen reservas finitas y no se regeneran.
- Cada orden reserva existencias de una fuente antes de entrar en la cola.
- Los trabajos consumen tiempo y entregan recursos al completarse.
- La capacidad del almacén limita la entrada; el excedente producido queda pendiente y no se pierde.
- La asignación respeta prioridades y favorece al colono con mayor especialización.
- Los colonos suspenden el trabajo cuando sus necesidades alcanzan umbrales críticos.
- Los colonos recorren la cuadrícula; el cambio de nivel solo es posible por el ascensor.

## Capas pendientes

1. Movimiento visual continuo, colisiones, obstáculos y navegación alrededor de instalaciones.
2. Comportamiento autónomo completo: buscar comida, agua, cama, refugio y atención médica.
3. Cultivos con siembra, crecimiento, mantenimiento y cosecha.
4. Construcción funcional, habitaciones, camas, almacenes y talleres.
5. Minería por vetas, herramientas, desgaste, transporte y fabricación.
6. Temperatura de habitaciones, aislamiento, enfermedades, accidentes y eventos.
7. Guardado local versionado, carga y recuperación segura.
8. Modos Campaña, Supervivencia y Sandbox.
9. Interfaz móvil completa, arte y audio originales.

## Validación y compilación

- GitHub Actions ejecuta importación del proyecto y pruebas de lógica.
- La validación automática no exporta APK.
- No se generará APK durante el desarrollo.
- La exportación final requerirá que el juego esté completo, validado y autorización expresa.

## Restricciones

- Sin servidores, anuncios, analítica ni conexión obligatoria.
- Sin servicios de pago.
- Código, arte, audio y contenido originales.
