# Dwarf Land — Arquitectura técnica

## Estructura
- `scripts/models/colonist.gd`: necesidades, salud, temperatura, profesión, posición lógica y movimiento interpolado.
- `scripts/models/resource_node.gd`: fuente finita o renovable, capa, celda 2D y reserva.
- `scripts/models/work_order.gd`: prioridad, destino, progreso y estado.
- `scripts/systems/inventory.gd`: inventario y capacidad.
- `scripts/systems/save_system.gd`: guardado JSON local versionado, escritura temporal y recuperación desde copia de seguridad.
- `scripts/models/crop_field.gd`: ciclo de cultivo, humedad, celda 2D, maduración, cosecha y resiembra.
- `scripts/systems/navigation_grid.gd`: navegación heredada por capa y nueva cuadrícula espacial 2D (X/Y + capa Z), con rutas alternativas, ascensor, obstáculos y excavación.
- `scripts/systems/world_generator.gd`: distribución reproducible de recursos y bloques geológicos excavables para la cuadrícula 2D.
- `scripts/systems/work_scheduler.gd`: asignación por especialidad, movimiento, órdenes de trabajo y excavación desde una celda adyacente.
- `scripts/systems/colony_simulation.gd`: reloj, necesidades, recursos, producción y alertas.
- `tests/`: pruebas automatizadas.

## Modelo espacial

El juego es estrictamente 2D lateral: no utiliza cámara, escena, física ni renderizado 3D. La cuadrícula lógica usa `Vector3i(x, y, capa)` únicamente como una tupla de datos para identificar la capa; las posiciones visuales y el dibujo se proyectan en `Vector2`. El mapa tiene 40 columnas por 12 filas en cada una de las tres capas, representadas simultáneamente en la vista lateral. El generador crea cámaras y bloques geológicos reproducibles en las capas subterráneas, dejando abierto el corredor de acceso y la columna del ascensor; el estado de esos bloques se conserva en el guardado local. La navegación admite cuatro direcciones cardinales, obstáculos y rutas alternativas mediante búsqueda en anchura. El ascensor conecta las tres capas únicamente en su celda de acceso. La cuadrícula 2D es ahora la referencia para movimiento, excavación, recursos, cultivos y construcción. Los edificios ocupan celdas sólidas y esa ocupación se restaura desde el guardado. Se mantiene una API `Vector2i` de compatibilidad para pruebas y operaciones heredadas que se está retirando gradualmente.

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
- Campaña registra objetivos de almacén, taller y día 10; Supervivencia es abierta; Sandbox suspende el desgaste de necesidades y temperatura.
- Los eventos diarios usan un generador aleatorio con estado persistido; enfermedad y lesiones progresan y se recuperan durante el descanso.
- Campaña registra objetivos de almacén, taller y día 10; Supervivencia es abierta; Sandbox suspende el desgaste de necesidades y temperatura.
- La construcción reserva materiales al crear la orden; almacenes amplían la capacidad y camas construidas se añaden a la asignación nocturna.
- La minería reserva herramientas, aplica desgaste por material y devuelve la herramienta si no se rompe; el taller convierte madera y mineral en herramientas. Las estructuras se mantienen transitables hasta incorporar navegación con varias rutas.

## Validación
- GitHub Actions importa el proyecto y ejecuta pruebas de lógica.
- El guardado automático se ejecuta cada seis horas de juego y al suspender o cerrar la aplicación.
- El flujo de validación no exporta APK.
- No se compilará APK durante el desarrollo.
- La exportación final requiere juego completo, pruebas superadas y autorización expresa.

## Pendiente
- Retirar por completo la API heredada `Vector2i` tras migrar los últimos casos de compatibilidad y las pruebas.
- Ampliar la generación procedural con vetas y depósitos geológicos diferenciados por tipo de recurso.
- Logística/transporte entre fuentes, colonos, almacenes y talleres.
- Habitaciones, aislamiento y sistemas avanzados de producción.
- Enfermedades, accidentes y eventos ambientales.
- Interfaz móvil adaptable, arte/audio finales y pruebas Android reales.
