# Dwarf Land

**Dwarf Land** es un juego original de supervivencia y gestión de colonos en un mundo subterráneo 2D lateral.

> Organiza una pequeña comunidad de enanos, administra sus necesidades y mantén el refugio funcionando bajo tierra.

## Estado del proyecto

**Fase:** prototipo inicial  
**Versión:** 0.1.0  
**Motor:** Godot 4.7.2 estable  
**Lenguaje:** GDScript  
**Plataforma objetivo:** Android  
**Conectividad:** juego local, sin servidores, anuncios ni telemetría.

## Pilares de diseño

- Exactamente dos niveles subterráneos jugables.
- Vista 2D lateral.
- Supervivencia basada en necesidades y consumo de recursos.
- Colonos con actividad autónoma y órdenes del jugador.
- Construcción, extracción y producción.
- Tres modos previstos: Campaña, Supervivencia y Sandbox.
- Arte, código, audio y contenido originales; no se reutilizan recursos del juego de referencia.

## Ejecutar el prototipo

1. Descarga Godot **4.7.2 estable** desde [godotengine.org](https://godotengine.org/download/).
2. Abre el proyecto seleccionando el archivo `project.godot`.
3. Ejecuta la escena principal con F6/F5.

## Compilación Android

El repositorio incluye un flujo de GitHub Actions para validar y exportar un APK de depuración. Se ejecuta al actualizar `main` o manualmente desde la pestaña **Actions**. El APK se publica como artefacto de la ejecución.

La primera compilación usa firma de depuración. Para distribuir actualizaciones instalables sobre una versión anterior necesitaremos configurar una clave de firma privada y persistente mediante GitHub Secrets; nunca se guardará en este repositorio público.

## Estructura

- `scenes/`: escenas Godot.
- `scripts/`: lógica del juego.
- `docs/`: diseño y decisiones técnicas.
- `.github/workflows/`: automatización de validación y compilación.

## Coste

El proyecto se desarrolla con herramientas gratuitas y de código abierto. No se incorporan servicios de pago, publicidad ni infraestructura en la nube para el funcionamiento del juego.

## Licencias

El código propio de este repositorio se publica bajo MIT; consulta `LICENSE`. Godot Engine se distribuye bajo su propia licencia MIT. Los avisos de terceros y recursos externos se documentarán antes de incorporarlos.

## Créditos

Proyecto independiente **Dwarf Land**. Inspiración de género: simuladores de colonias y supervivencia subterránea. No está afiliado ni utiliza contenido propietario de otros juegos.
