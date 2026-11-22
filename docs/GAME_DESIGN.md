# Dwarf Land — Documento de diseño

## Visión
Juego original de supervivencia y gestión de una colonia de enanos en un mundo lateral estrictamente 2D. La supervivencia depende de una economía material coherente: los recursos aparecen en la capa donde corresponde encontrarlos, los colonos los extraen, los transportan y los almacenan.

## Estructura del mundo: tres capas simultáneas

El mapa muestra las tres capas horizontales al mismo tiempo. Cada capa tiene una cuadrícula de 40 columnas por 12 filas. La coordenada de capa es un dato lógico; no existe renderizado ni escena 3D.

### Superficie
- Árboles, vegetación, madera y suelo fértil.
- Cultivos y alimentos.
- Accesos al subsuelo.

### Subsuelo
- Tierra, raíces y depósitos de arcilla.
- Acuíferos y agua subterránea.
- Cámaras y galerías excavables.

### Profundidad
- Roca madre y piedra.
- Vetas minerales y carbón.
- Extracción que requiere herramientas.

Un ascensor conecta las tres capas en una posición fija. Las cavernas y bloques geológicos se generan con una semilla reproducible; el corredor de acceso y el hueco del ascensor permanecen abiertos.

## Supervivencia y colonia
- Colonos autónomos para tareas rutinarias; el jugador define prioridades y órdenes.
- Necesidades: hambre, sed, sueño/fatiga, salud y temperatura.
- Descanso nocturno: cada colono busca una cama libre y recupera fatiga al llegar.
- Temperatura distinta por capa, horario y refugio; la exposición extrema puede dañar la salud.
- Fuentes renovables y depósitos finitos; inventario con capacidad.
- Hongos subterráneos renovables para fabricar medicina.
- Recolección y extracción mediante órdenes de trabajo.
- Los colonos transportan físicamente los recursos hasta el punto de almacenamiento. La carga y las órdenes de entrega se conservan al guardar.
- Cultivos con humedad, crecimiento diario, cosecha y resiembra.
- Construcción de camas, almacenes y talleres en celdas del mapa. Las estructuras sólidas bloquean el paso; las camas permanecen accesibles.
- Taller con fabricación de herramientas y medicina; las herramientas se desgastan durante la extracción y la medicina reduce enfermedad y lesión.
- Enfermedades y lesiones básicas, alertas y recuperación mediante descanso.
- Campaña: construir un almacén y un taller y alcanzar el día 10.
- Supervivencia: administrar la colonia sin objetivo final.
- Sandbox: construir y producir sin desgaste de hambre, sed, fatiga ni temperatura.
- Funcionamiento local/offline, sin anuncios, telemetría, servidores ni servicios de pago.
- Código, arte, música y contenido originales.

## Estado de implementación

El núcleo de simulación incluye:
- Tres capas visibles simultáneamente y selección táctil de capa/celda.
- Cuadrícula 2D con rutas cardinales, obstáculos, ascensor y rutas alternativas.
- Generación reproducible de cámaras y bloques excavables en subsuelo y profundidad.
- Movimiento interpolado de colonos, excavación por órdenes y apertura de celdas.
- Construcción en el mapa 2D, ocupación sólida, camas accesibles y persistencia de edificios.
- Recolección, carga y entrega física de recursos en el almacén; persistencia de carga en tránsito.
- Cultivos con humedad, maduración, cosecha y resiembra.
- Necesidades, descanso, temperatura, enfermedades y lesiones básicas, con tratamiento médico mediante medicina fabricada.
- Inventario, almacenes, taller y fabricación de herramientas.
- Guardado local versionado, copia de seguridad, recuperación y guardado automático.
- Modos Campaña, Supervivencia y Sandbox.
- Pruebas automatizadas ejecutadas con Godot 4.7.2 en GitHub Actions.

## Trabajo pendiente
1. Logística avanzada: distribuir recursos entre varios almacenes, abastecer talleres y gestionar prioridades de almacenamiento.
2. Generación geológica más rica: vetas por material, acuíferos, cavernas conectadas, suelos y biomas.
3. Sistema completo de habitaciones, aislamiento, temperatura interior y calidad de vivienda.
4. Progresión de campaña, eventos ambientales, medicina y tratamientos de enfermedades/lesiones.
5. Interfaz móvil adaptable a distintas resoluciones, controles táctiles refinados y accesibilidad.
6. Sustituir gráficos provisionales por arte original definitivo, animaciones y audio.
7. Pruebas visuales, funcionales y de rendimiento en dispositivos Android reales.

## Validación y entrega
GitHub Actions importa el proyecto y ejecuta pruebas de lógica con Godot 4.7.2. Esta validación no sustituye las pruebas visuales ni la ejecución en un teléfono real.

No se compilará ni publicará APK hasta que el juego esté completo, las pruebas aplicables estén superadas y exista autorización expresa para la compilación final.
