# Dwarf Land — Plan de pruebas

Este documento define comprobaciones obligatorias. No implica que ya se hayan ejecutado.

## Simulación y necesidades

- [ ] El reloj avanza una hora por paso y cambia el día correctamente.
- [ ] Pausar detiene el tiempo; reanudar continúa desde el mismo estado.
- [ ] Hambre, sed y fatiga permanecen dentro de 0–100.
- [ ] La comida y el agua se consumen solo si existen unidades disponibles.
- [ ] La falta prolongada de comida o agua afecta la salud.
- [ ] En condiciones ambientales normales la temperatura corporal permanece estable.
- [ ] El frío y el calor extremos afectan la temperatura corporal y, si persisten, la salud.

## Fuentes de recursos

- [ ] Las fuentes renovables se regeneran al cambiar el día sin superar su capacidad.
- [ ] Las vetas minerales y canteras se agotan y no se regeneran.
- [ ] No se puede reservar más recurso del que una fuente contiene.
- [ ] Una orden agotada o inválida no consume existencias.

## Inventario y producción

- [ ] El inventario no acepta cantidades negativas.
- [ ] El inventario no supera su capacidad.
- [ ] Las salidas de producción que no caben quedan pendientes y no se pierden.
- [ ] Cada orden requiere el tiempo de trabajo definido.
- [ ] La prioridad más alta se asigna antes que las prioridades inferiores.
- [ ] Cada profesión aplica su bonificación solo a trabajos compatibles.
- [ ] Un colono con necesidades críticas suspende su trabajo hasta recuperarse.
- [ ] Un colono no puede ejecutar dos órdenes simultáneamente.
- [ ] Una orden completada entrega exactamente la cantidad definida.
- [ ] Una orden no produce recursos si está cancelada o no se ha completado.

## Niveles y colonos

- [ ] Solo existen los niveles jugables 1 y 2.
- [ ] No se puede seleccionar ni crear un tercer nivel.
- [ ] Un colono tarda tiempo en cambiar de nivel.
- [ ] Los colonos se muestran en el nivel donde se encuentran.
- [ ] Un colono fallecido no continúa trabajando ni consumiendo recursos.

## Persistencia y Android (etapa posterior)

- [ ] Guardar y cargar conserva hora, día, inventario, colonos, órdenes y estado de la colonia.
- [ ] Un guardado dañado no destruye automáticamente una partida válida anterior.
- [ ] La interfaz se adapta a resoluciones y relaciones de aspecto Android.
- [ ] Los controles táctiles son utilizables y no se solapan.
- [ ] La simulación mantiene rendimiento estable en el dispositivo objetivo.
- [ ] No se requieren red, cuenta, anuncios ni servicios externos.

## Criterio de salida

No se genera APK final hasta que los sistemas acordados estén implementados, los casos aplicables estén superados, los defectos bloqueantes estén corregidos y el usuario autorice la exportación.
