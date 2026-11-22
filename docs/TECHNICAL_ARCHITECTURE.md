# Dwarf Land — Arquitectura técnica

## Estructura
- `scripts/models/colonist.gd`: necesidades, salud, temperatura, profesión, posición lógica y movimiento interpolado.
- `scripts/models/resource_node.gd`: fuente finita o renovable, capa, ubicación y reserva.
- `scripts/models/work_order.gd`: prioridad, destino, progreso y estado.
- `scripts/systems/inventory.gd`: inventario y capacidad.
- `scripts/systems/save_system.gd`: guardado JSON local versionado, escritura temporal y recuperación desde copia de seguridad.
- `scripts/models/crop_field.gd`: ciclo de cultivo, humedad, maduración, cosecha y resiembra.
- `scripts/systems/navigation_grid.gd`: cuadrícula de tres capas, ascensor, obstáculos, bloques excavables y celdas excavadas.
- `scripts/systems/world_generator.gd`: distribución reproducible de recursos a partir de una semilla persistente.
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
- La distribución respeta el entorno: madera y cultivos en superficie, agua y arcilla en subsuelo, roca, carbón y mineral en profundidad.
- Una semilla guardada genera variaciones reproducibles en las posiciones de varios recursos; algunos obstáculos y el depósito principal de piedra aún son fijos.
- Los cultivos maduran por días, necesitan humedad, consumen agua cuando hay reservas y se replantan usando semillas.
- En el horario nocturno, el planificador libera trabajos, asigna camas libres y los colonos recuperan fatiga al llegar al refugio.
- La temperatura local depende de la capa, la hora y el refugio; la exposición extrema reduce la salud y activa alertas.
- La construcción reserva materiales al crear la orden; almacenes amplían la capacidad y camas construidas se añaden a la asignación nocturna.
- La minería reserva herramientas, aplica desgaste por material y devuelve la herramienta si no se rompe; el taller convierte madera y mineral en herramientas. Las estructuras se mantienen transitables hasta incorporar navegación con varias rutas.

## Validación
- GitHub Actions importa el proyecto y ejecuta pruebas de lógica.
- El guardado automático se ejecuta cada seis horas de juego y al suspender o cerrar la aplicación.
- El flujo de validación no exporta APK.
- No se compilará APK durante el desarrollo.
- La exportación final requiere juego completo, pruebas superadas y autorización expresa.

## Pendiente
- Navegación 2D real, rutas alternativas y colisiones de estructuras.
- Generación procedural de mapas y depósitos con semilla persistente.
- Logística/transporte entre fuentes, colonos, almacenes y talleres.
- Habitaciones, aislamiento y sistemas avanzados de producción.
- Enfermedades, accidentes y eventos ambientales.
- Modos de juego y progresión de campaña.
- Interfaz móvil adaptable, arte/audio finales y pruebas Android reales.
