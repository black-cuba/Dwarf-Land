# Dwarf Land

**Dwarf Land** es un juego original de supervivencia y gestión de colonos en un mundo subterráneo 2D lateral.

> Organiza una pequeña comunidad de enanos, administra sus necesidades y mantén el refugio funcionando bajo tierra.

## Estado del proyecto

**Fase:** núcleo de simulación y trabajos autónomos en desarrollo  
**Versión:** 0.1.0  
**Motor:** Godot 4.7.2 estable  
**Lenguaje:** GDScript  
**Plataforma objetivo:** Android  
**Conectividad:** juego local, sin servidores, anuncios ni telemetría.

## Pilares de diseño

- Exactamente dos niveles subterráneos jugables.
- Vista 2D lateral.
- Supervivencia basada en necesidades, fuentes limitadas y consumo de recursos.
- Colonos con actividad autónoma y órdenes del jugador.
- Construcción, extracción y producción.
- Tres modos previstos: Campaña, Supervivencia y Sandbox.
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
- `.github/workflows/`: automatización de validación y compilación.

## Coste

El proyecto se desarrolla con herramientas gratuitas y de código abierto. No se incorporan servicios de pago, publicidad ni infraestructura en la nube para el funcionamiento del juego.

## Licencias y propiedad intelectual

El repositorio es público para facilitar el desarrollo y la revisión, pero eso no significa que el contenido original de Dwarf Land tenga una licencia de reutilización. No se concede una licencia abierta sobre el código, arte, personajes, historia ni demás contenido propio. Las licencias de Godot y de cualquier dependencia o recurso de terceros se respetarán y documentarán por separado.

## Créditos

Proyecto independiente **Dwarf Land**. Inspiración de género: simuladores de colonias y supervivencia subterránea. No está afiliado ni utiliza contenido propietario de otros juegos.
