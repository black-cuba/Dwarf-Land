# Dwarf Land

**Dwarf Land** es un juego original de supervivencia y gestión de colonos en un mundo 2D lateral con superficie y dos capas subterráneas.

> Organiza una pequeña comunidad de enanos, administra sus necesidades y mantén el refugio funcionando bajo tierra.

## Estado del proyecto

**Fase:** núcleo de simulación y trabajos autónomos en desarrollo  
**Versión:** 0.1.0  
**Motor:** Godot 4.7.2 estable  
**Lenguaje:** GDScript  
**Plataforma objetivo:** Android  
**Conectividad:** juego local, sin servidores, anuncios ni telemetría.

## Pilares de diseño

- Tres capas jugables visibles simultáneamente: superficie, subsuelo y profundidad.
- Semilla de mundo reproducible con variación inicial de bosques, acuíferos, arcilla y vetas minerales.
- Vista 2D lateral con las tres capas visibles a la vez, sin renderizado ni escenas 3D.
- Mapa de 40 × 12 celdas por capa, excavación en distintas filas y desplazamiento entre capas mediante ascensor.
- Supervivencia basada en necesidades, fuentes limitadas y consumo de recursos.
- Colonos con actividad autónoma, profesiones y órdenes del jugador.
- Recursos distribuidos por capa: árboles y cultivos en superficie, agua, arcilla y hongos medicinales en subsuelo, roca y minerales en profundidad.
- Generación de cavernas reproducibles, excavación de bloques geológicos y apertura de rutas transitables.
- Construcción sobre celdas 2D con ocupación sólida, persistencia y asignación de camas mediante rutas.
- Transporte físico de recursos: los colonos recogen materiales, los cargan y los llevan al almacén; la carga sobrevive al guardado.
- Selección táctil directa de la capa y celda en el mapa completo.
- Movimiento interpolado de colonos y guardado local automático con copia de seguridad.
- Ciclo agrícola básico: crecimiento diario condicionado por humedad, cosecha y resiembra.
- Descanso nocturno autónomo con asignación de camas, rutas por la cuadrícula 2D y recuperación de fatiga.
- Temperatura ambiental variable por capa y horario, con exposición al frío/calor y alertas.
- Construcción con costes de materiales, órdenes de trabajo, camas adicionales y almacenes que amplían la capacidad.
- Taller que fabrica herramientas y medicina; la minería consume herramientas y aplica desgaste hasta romperlas, y la medicina permite tratar enfermedades y lesiones.
- Construcción, extracción y producción.
- Tres modos: Campaña (almacén + taller + día 10), Supervivencia sin objetivo final y Sandbox sin desgaste de necesidades.
- Enfermedades por estrés y eventos diarios; los accidentes de minería pueden causar lesiones recuperables con descanso.
- Arte, código, audio y contenido originales; no se reutilizan recursos del juego de referencia.

## Ejecutar el prototipo

1. Descarga Godot **4.7.2 estable** desde [godotengine.org](https://godotengine.org/download/).
2. Abre el proyecto seleccionando el archivo `project.godot`.
3. Ejecuta la escena principal con F6/F5.

## APK y lanzamientos

La compilación Android está desactivada durante el desarrollo. No se generarán APK de prueba ni versiones incompletas. La APK final se preparará únicamente cuando todos los sistemas acordados estén implementados, las pruebas estén superadas y exista autorización expresa para la compilación final.

La firma de distribución se configurará al llegar a esa etapa, usando un secreto privado fuera del repositorio público.

## Estructura

- `scenes/`: escenas Godot.
- `scripts/`: lógica del juego.
- `docs/`: diseño y decisiones técnicas.
- `.github/workflows/`: validación automática del proyecto y las reglas de juego; no compila APK.

## Coste

El proyecto se desarrolla con herramientas gratuitas y de código abierto. No se incorporan servicios de pago, publicidad ni infraestructura en la nube para el funcionamiento del juego.

## Licencias y propiedad intelectual

El repositorio es público para facilitar el desarrollo y la revisión, pero eso no significa que el contenido original de Dwarf Land tenga una licencia de reutilización. No se concede una licencia abierta sobre el código, arte, personajes, historia ni demás contenido propio. Las licencias de Godot y de cualquier dependencia o recurso de terceros se respetarán y documentarán por separado.

## Créditos

Proyecto independiente **Dwarf Land**. Inspiración de género: simuladores de colonias y supervivencia subterránea. No está afiliado ni utiliza contenido propietario de otros juegos.
