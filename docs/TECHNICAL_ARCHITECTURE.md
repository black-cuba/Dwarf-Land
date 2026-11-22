# Dwarf Land — Arquitectura técnica

## Estructura
- `scripts/models/colonist.gd`: necesidades, salud, temperatura, profesión, posición lógica y movimiento interpolado.
- `scripts/models/resource_node.gd`: fuente finita o renovable, capa, ubicación y reserva.
- `scripts/models/work_order.gd`: prioridad, destino, progreso y estado.
- `scripts/systems/inventory.gd`: inventario y capacidad.
- `scripts/systems/save_system.gd`: guardado JSON local versionado, escritura temporal y recuperación desde copia de seguridad.
- `scripts/models/crop_field.gd`: ciclo de cultivo, humedad, maduración, cosecha y resiembra.
- `scripts/systems/navigation_grid.gd`: cuadrícula de tres capas, ascensor, obstáculos, bloques excavables y celdas excavadas.
- `scripts/systems/work_scheduler.gd`: asignación por especialidad, movimiento, órdenes de trabajo y excavación desde una celda adyacente.
- `scripts/systems/colony_simulation.gd`: reloj, necesidades, recursos, producción y alertas.
- `tests/`: pruebas automatizadas.

## Modelo espacial
- Capa 0: superficie (árboles, suelo fértil y cultivos).
- Capa 1: subsuelo (tierra, raíces, arcilla y agua subterránea).
- Capa 2: profundidad (roca madre, piedra y vetas minerales).
- La cuadrícula solo permite tres capas.
- El ascensor es la conexión vertical entre capas adyacentes.
- Las fuentes de recursos declaran su capa y celda; las órdenes navegan hasta ellas.

## Reglas de recursos
- Las fuentes renovables se regeneran diariamente sin superar su capacidad.
- Los depósitos de piedra y mineral son finitos.
- Cada orden de extracción reserva existencias antes de entrar en cola.
- La excavación se ejecuta desde una celda adyacente y abre el paso al completar el trabajo.
- Los trabajos consumen tiempo y entregan producción al inventario.
- El inventario limita la entrada; el excedente permanece pendiente.
- La distribución inicial respeta el entorno: madera y cultivos en superficie, agua y arcilla en subsuelo, roca, carbón y mineral en profundidad.
- Los cultivos maduran por días, necesitan humedad, consumen agua cuando hay reservas y se replantan usando semillas.
- En el horario nocturno, el planificador libera trabajos, asigna camas libres y los colonos recuperan fatiga al llegar al refugio.
- La temperatura local depende de la capa, la hora y el refugio; la exposición extrema reduce la salud y activa alertas.

## Validación
- GitHub Actions importa el proyecto y ejecuta pruebas de lógica.
- El guardado automático se ejecuta cada seis horas de juego y al suspender o cerrar la aplicación.
- El flujo de validación no exporta APK.
- No se compilará APK durante el desarrollo.
- La exportación final requiere juego completo, pruebas superadas y autorización expresa.

## Pendiente
Movimiento continuo, excavación y generación de mapas; autonomía completa; cultivos avanzados; construcción; habitaciones; talleres; herramientas; transporte; eventos; guardado; modos de juego; interfaz móvil y arte/audio finales.
