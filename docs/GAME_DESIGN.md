# Dwarf Land — Documento de diseño inicial

## Visión

Juego original de supervivencia y gestión de una pequeña colonia de enanos bajo tierra. La presión principal nace de mantener con vida a la comunidad mediante producción, almacenamiento y decisiones de gestión.

## Reglas de alcance confirmadas

- Cámara 2D lateral.
- Exactamente dos niveles subterráneos jugables.
- No existe un tercer nivel ni una superficie jugable.
- Colonos autónomos en labores rutinarias; el jugador fija prioridades y da órdenes importantes.
- El juego debe funcionar sin conexión, sin anuncios y sin telemetría.
- No se copiarán código, personajes, mapas, sonidos ni imágenes de otros juegos.

## Distribución de los niveles

### Nivel 1 — Refugio y producción
Vivienda, camas, almacenamiento, agua, alimentos, cultivos y espacios de trabajo.

### Nivel 2 — Extracción y materiales
Minería, piedra, minerales, materias primas y acceso al taller. El ascensor conecta ambos niveles.

## Sistemas de supervivencia

Necesidades individuales previstas:
- Hambre.
- Sed.
- Sueño y fatiga.
- Salud.
- Temperatura y condiciones ambientales.

Recursos colectivos previstos:
- Comida y agua.
- Madera, piedra y minerales.
- Herramientas y materiales de construcción.
- Reservas y capacidad de almacenamiento.

## Gestión de colonos

Los colonos realizan trabajos rutinarios de forma autónoma. El jugador podrá establecer prioridades, asignar trabajos y atender alertas. La simulación debe considerar necesidades, disponibilidad de recursos y desplazamiento entre niveles.

## Modos previstos

1. Campaña.
2. Supervivencia.
3. Sandbox.

Los modos se implementarán después de estabilizar el núcleo de simulación.

## Estado de implementación

La base visual inicial se está sustituyendo progresivamente por sistemas separados y mantenibles. Ya existe una primera versión de:
- Modelo individual de colono con hambre, sed, fatiga, salud y temperatura corporal.
- Inventario con cantidades y capacidad máxima.
- Reloj de simulación por horas.
- Cola de trabajos con prioridades y asignación autónoma de colonos.
- Producción de comida, agua, madera y piedra mediante trabajos que consumen tiempo.
- Desplazamiento lógico entre los dos niveles y alertas de reservas.

Estos sistemas son una primera capa técnica. Todavía no equivalen a la simulación completa: faltan fuentes físicas de recursos, rutas y desplazamiento espacial, profesiones con rendimiento diferenciado, cultivos, construcción funcional, habitaciones, herramientas, enfermedades, eventos, guardado y modos de juego.

## Prototipo 0.1.0

La primera escena verifica:
- Renderizado lateral de los dos niveles.
- Representación básica de colonos.
- Reservas de comida, agua, madera y piedra.
- Avance del tiempo y consumo diario.
- Cambio de nivel.
- Acciones básicas de recolección, extracción y descanso.
- Interfaz adaptable a pantalla táctil.

Esta versión es una base de validación, no representa el contenido final ni todos los sistemas acordados.

## Próximos hitos

1. Validar apertura y compilación del proyecto.
2. Separar entidades, necesidades, inventario y simulación en sistemas mantenibles.
3. Implementar navegación y trabajos autónomos reales.
4. Construcción y producción con costes y tiempos.
5. Eventos, salud, temperatura y condiciones ambientales.
6. Guardado local y pruebas de rendimiento en Android.
7. Incorporar arte y audio originales.
8. Completar Campaña, Supervivencia y Sandbox.
