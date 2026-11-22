# Dwarf Land — Documento de diseño

## Visión

Juego original de supervivencia y gestión de una colonia de enanos bajo tierra. La presión principal nace de mantener con vida a la comunidad mediante producción, almacenamiento, planificación y decisiones de gestión.

## Alcance confirmado

- Vista 2D lateral.
- Exactamente dos niveles subterráneos jugables.
- Sin superficie jugable ni tercer nivel.
- Colonos autónomos en tareas rutinarias; el jugador fija prioridades y da órdenes importantes.
- Juego sin conexión, sin anuncios, sin telemetría y sin servicios externos.
- No se copiarán código, personajes, mapas, sonidos ni imágenes de otros juegos.
- Tres modos previstos: Campaña, Supervivencia y Sandbox.

## Distribución de los niveles

### Nivel 1 — Refugio y producción

Vivienda, camas, almacenamiento, agua, alimentos, cultivos y espacios de trabajo.

### Nivel 2 — Extracción y materiales

Minería, piedra, minerales, materias primas y taller. El ascensor conecta ambos niveles.

## Necesidades de cada colono

- Hambre.
- Sed.
- Sueño y fatiga.
- Salud.
- Temperatura corporal y condiciones ambientales.

## Recursos colectivos

- Comida y agua.
- Madera, piedra y minerales.
- Herramientas y materiales de construcción.
- Reservas y capacidad de almacenamiento.

## Estado de implementación

Ya existe una primera base funcional del núcleo de simulación:

- Modelo individual de colono con necesidades, salud, temperatura y profesión.
- Inventario con capacidad máxima.
- Fuentes subterráneas finitas y renovables: cultivo de hongos, manantial, madera fúngica, cantera y veta mineral.
- Regeneración diaria de fuentes renovables y agotamiento de depósitos minerales.
- Reloj de simulación por horas.
- Cola de trabajos con prioridades.
- Asignación de tareas favoreciendo la profesión más adecuada.
- Pausa de trabajo ante hambre, sed o fatiga críticas.
- Producción con tiempo de trabajo y entrega real al inventario.
- Cuadrícula de dos niveles con ruta obligatoria por el ascensor.
- Indicadores básicos de necesidades y reservas en pantalla.
- Pruebas automatizadas de inventario, fuentes, navegación, necesidades y trabajos.

Esta base todavía no representa el juego final. El movimiento es por pasos de simulación y faltan sistemas completos de construcción, agricultura, vivienda, fabricación, eventos, persistencia y modos.

## Próximos hitos

1. Movimiento visual continuo, colisiones y navegación alrededor de instalaciones.
2. Comportamiento autónomo completo para comer, beber, dormir, trabajar y recuperarse.
3. Cultivos con siembra, crecimiento y cosecha.
4. Construcción, habitaciones, camas, almacenes y talleres funcionales.
5. Minería, herramientas, fabricación, desgaste y transporte.
6. Temperatura ambiental, aislamiento, enfermedades, accidentes y eventos.
7. Guardado local seguro y recuperación de partidas.
8. Interfaz móvil completa, arte y audio originales.
9. Campaña, Supervivencia y Sandbox.
10. Pruebas completas en dispositivo Android y corrección final.

## Regla de entrega

No se compilará ni publicará una APK hasta que el juego esté completo, las pruebas estén superadas y exista autorización expresa para la compilación final.
