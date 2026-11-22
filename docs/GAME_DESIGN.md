# Dwarf Land — Documento de diseño

## Visión
Juego original de supervivencia y gestión de una colonia de enanos en un mundo lateral 2D. La supervivencia depende de una economía material coherente: cada recurso aparece en el entorno donde tendría sentido encontrarlo y debe extraerse, transportarse, almacenarse y consumirse.

## Estructura del mundo: tres capas

El mundo jugable tiene exactamente tres capas conectadas por un ascensor o acceso vertical seguro:

### Capa 1 — Superficie: árboles, vegetación y suelo
- Árboles y madera.
- Suelo fértil, hierba y cultivos.
- Alimentos de superficie y espacio para agricultura.
- Entradas a galerías y zonas de excavación.

### Capa 2 — Subsuelo: tierra y zona de raíces
- Tierra compacta, raíces y depósitos de arcilla.
- Acuíferos y corrientes de agua subterránea.
- Hongos y recursos orgánicos que prosperan sin luz.
- Transición geológica entre suelo y roca.

### Capa 3 — Profundidad: roca madre y yacimientos
- Roca compacta y piedra de construcción.
- Vetas minerales y depósitos geológicos.
- Materiales más profundos, con extracción más exigente.
- Mayor presión ambiental y logística conforme se amplíen los sistemas de supervivencia.

La distribución respeta reglas ecológicas/geológicas. La generación inicial ya usa una semilla reproducible para variar la posición de bosques, acuíferos, arcilla y vetas de mineral/carbón; la roca principal y los primeros obstáculos siguen siendo fijos.

## Supervivencia y colonia
- Colonos autónomos en tareas rutinarias; el jugador establece prioridades y órdenes importantes.
- Necesidades: hambre, sed, sueño/fatiga, salud y temperatura.
- Durante la noche, los colonos suspenden sus trabajos, buscan una cama libre en el refugio y recuperan más fatiga al dormir.
- La superficie, el subsuelo y la profundidad tienen temperaturas distintas; la exposición térmica puede dañar la salud y generar alertas.
- Las construcciones consumen materiales y requieren trabajo; los almacenes amplían capacidad y las camas aumentan los puestos de descanso.
- Recursos: comida, agua, madera, tierra/arcilla, piedra, minerales, herramientas y materiales.
- Vivienda, almacenes, talleres, cultivos e instalaciones.
- Campaña: construir un almacén y un taller y alcanzar el día 10.
- Supervivencia: administrar la colonia sin objetivo final.
- Sandbox: construir y producir sin desgaste de hambre, sed, fatiga ni temperatura.
- Juego offline, sin anuncios, telemetría, servidores ni servicios de pago.
- Código, arte, música y contenido originales; no se copia material protegido de otros juegos.

## Estado de implementación

La versión de desarrollo ya incorpora:
- Simulación de tres capas con distribución ecológica/geológica inicial.
- Fuentes renovables y depósitos finitos, inventario con capacidad y cola de trabajos.
- Movimiento interpolado y excavación de bloques mediante órdenes.
- Agricultura básica con humedad, crecimiento por días, cosecha y resiembra.
- Descanso nocturno con tres camas iniciales y camas construidas.
- Temperatura variable por capa y horario, exposición térmica y alertas.
- Construcción con costes de madera/piedra; almacenes amplían la capacidad.
- Taller con receta de fabricación de herramientas y desgaste por extracción.
- Guardado local versionado, copia de seguridad, recuperación y guardado manual.
- Tres modos: Campaña (almacén, taller y día 10), Supervivencia abierta y Sandbox sin desgaste de necesidades.
- Generación reproducible mediante semilla para variar parte de los recursos.
- Enfermedades progresivas por estrés, eventos diarios y lesiones ocasionales por accidentes mineros; descanso para recuperación.
- Pruebas automatizadas de lógica ejecutadas en GitHub Actions.

Limitaciones actuales:
- El mapa usa una sola línea de navegación por capa; todavía no tiene movimiento libre 2D, rutas alternativas ni colisiones completas.
- Las estructuras se dibujan y tienen efectos funcionales, pero siguen siendo transitables.
- La semilla varía varios depósitos, pero faltan galerías, vetas y obstáculos generados proceduralmente.
- Faltan transporte físico de materiales, habitaciones avanzadas, enfermedades, accidentes y eventos.
- La interfaz, el arte y el audio siguen siendo provisionales; falta validación en dispositivos Android reales.

## Próximos hitos
1. Rehacer la navegación como mapa 2D con rutas alternativas, colisiones y excavación de galerías.
2. Generación procedural completa de terreno y vetas.
3. Transporte de materiales y logística entre fuentes, colonos, almacenes y talleres.
4. Habitaciones, aislamiento y sistemas avanzados de producción.
5. Enfermedades, accidentes, eventos y ecología ambiental.
6. Interfaz móvil adaptable, controles táctiles completos, arte y audio originales.
7. Pruebas funcionales y de rendimiento en Android.

## Regla de entrega
No se compilará ni publicará APK hasta que el juego esté completo, las pruebas estén superadas y exista autorización expresa.
