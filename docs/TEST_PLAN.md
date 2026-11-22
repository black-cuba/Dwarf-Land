# Dwarf Land — Plan de pruebas

Este documento define los criterios de aceptación. Las casillas pendientes no se consideran superadas por el mero hecho de existir una prueba automatizada.

## Simulación y necesidades

- [ ] El reloj avanza una hora por paso y cambia el día correctamente.
- [ ] Pausar detiene el tiempo; reanudar continúa desde el mismo estado.
- [ ] Hambre, sed y fatiga permanecen dentro del rango 0–100.
- [ ] La comida y el agua se consumen solo si existen unidades disponibles.
- [ ] La falta prolongada de comida o agua afecta la salud.
- [ ] En ambiente templado la temperatura corporal permanece estable.
- [ ] El frío y el calor extremos afectan la temperatura corporal y, si persisten, la salud.

## Fuentes de recursos

- [ ] Las fuentes renovables se regeneran al cambiar el día sin superar su capacidad.
- [ ] Las vetas minerales y canteras se agotan y no se regeneran.
- [ ] No se puede reservar más recurso del que una fuente contiene.
- [ ] Las fuentes de cada recurso están ubicadas en el nivel correcto.

## Inventario y producción

- [ ] El inventario no acepta cantidades negativas.
- [ ] El inventario no supera su capacidad.
- [ ] Las salidas de producción que no caben quedan pendientes y no se pierden.
- [ ] Cada orden requiere el tiempo de trabajo definido.
- [ ] La prioridad más alta se asigna antes que las prioridades inferiores.
- [ ] Cada profesión aplica su bonificación solo a trabajos compatibles.
- [ ] Se selecciona al colono más cualificado disponible para cada orden.
- [ ] Un colono con necesidades críticas suspende su trabajo.
- [ ] Un colono no puede ejecutar dos órdenes simultáneamente.
- [ ] Una orden completada entrega exactamente la cantidad definida.

## Niveles y colonos

- [ ] Solo existen los niveles jugables 1 y 2.
- [ ] No se puede seleccionar ni crear un tercer nivel.
- [ ] No existe una conexión vertical distinta del ascensor.
- [ ] Los colonos recorren la cuadrícula hasta la fuente de recursos.
- [ ] Un colono tarda tiempo en desplazarse entre niveles.
- [ ] Las celdas bloqueadas no pueden atravesarse.
- [ ] Los colonos se muestran en el nivel y posición donde se encuentran.
- [ ] Un colono fallecido no continúa trabajando ni consumiendo recursos.

## Persistencia y Android

- [ ] Guardar y cargar conserva hora, día, inventario, colonos, fuentes, órdenes y estado de la colonia.
- [ ] Un guardado dañado no destruye automáticamente una partida válida anterior.
- [ ] La interfaz se adapta a resoluciones y relaciones de aspecto Android.
- [ ] Los controles táctiles son utilizables y no se solapan.
- [ ] La simulación mantiene rendimiento estable en el dispositivo objetivo.
- [ ] No se requieren red, cuenta, anuncios ni servicios externos.

## Criterio de salida

No se genera APK final hasta que los sistemas acordados estén implementados, los casos aplicables estén superados, los defectos bloqueantes estén corregidos y el usuario autorice la exportación.
