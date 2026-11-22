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

La distribución representa una regla ecológica/geológica, no una garantía de que cada mapa real tenga exactamente los mismos depósitos. Los yacimientos concretos variarán entre partidas cuando se implemente la generación del mundo.

## Supervivencia y colonia
- Colonos autónomos en tareas rutinarias; el jugador establece prioridades y órdenes importantes.
- Necesidades: hambre, sed, sueño/fatiga, salud y temperatura.
- Durante la noche, los colonos suspenden sus trabajos, buscan una cama libre en el refugio y recuperan más fatiga al dormir.
- Recursos: comida, agua, madera, tierra/arcilla, piedra, minerales, herramientas y materiales.
- Vivienda, almacenes, talleres, cultivos e instalaciones.
- Tres modos previstos: Campaña, Supervivencia y Sandbox.
- Juego offline, sin anuncios, telemetría, servidores ni servicios de pago.
- Código, arte, música y contenido originales; no se copia material protegido de otros juegos.

## Estado de implementación
La base funcional incluye necesidades, inventario, fuentes limitadas, trabajos con prioridades, especializaciones y navegación de tres capas. La primera versión de excavación distingue bloques de roca excavables de celdas transitables; los colonos pueden recibir órdenes de excavación desde la interfaz y abren el paso al completar el trabajo. El movimiento entre celdas se interpola visualmente. El estado de la colonia se guarda automáticamente cada seis horas de juego y al pasar la aplicación a segundo plano o cerrarla; se mantiene una copia de seguridad recuperable.

La primera base funcional incluye necesidades, inventario, fuentes limitadas, trabajos con prioridades, especializaciones, navegación de tres capas y pruebas automáticas. La distribución inicial ya separa cultivos y árboles en superficie, agua y arcilla en el subsuelo, y roca, carbón y minerales en profundidad.

Todavía faltan movimiento visual continuo, excavación de galerías extensas y terreno generado por mapa, cultivos avanzados, construcción, habitaciones, herramientas, transporte, eventos, guardado y los tres modos.

## Próximos hitos
1. Movimiento visual continuo y excavación de terreno.
2. Comportamiento autónomo para comer, beber, dormir y recuperarse.
3. Agricultura y ciclos de cultivo.
4. Construcción, habitaciones, camas, almacenes y talleres.
5. Geología, vetas, minería, herramientas y transporte.
6. Temperatura ambiental, aislamiento, enfermedades, accidentes y eventos.
7. Guardado local seguro.
8. Interfaz móvil, arte y audio originales.
9. Campaña, Supervivencia y Sandbox.
10. Pruebas completas en Android.

## Regla de entrega
No se compilará ni publicará APK hasta que el juego esté completo, las pruebas estén superadas y exista autorización expresa.
