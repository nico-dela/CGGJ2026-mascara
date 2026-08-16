# El Caso del Leñador
### Córdoba Global Game Jam 2026

**El Caso del Leñador** es una **aventura gráfica 2D** desarrollada durante la **Córdoba Global Game Jam 2026**.

El jugador investiga un caso extraño en un entorno reducido, interactuando con personajes y objetos, recolectando pistas y avanzando a través del diálogo y la observación.

---

## Sobre el juego

El Caso del Leñador propone una experiencia breve de misterio, donde el foco está puesto en:
- exploración
- diálogo
- narrativa ambiental

El juego fue diseñado para ser completado en una sola sesión, priorizando atmósfera y ritmo por sobre complejidad o duración.

---

## Género

- Aventura gráfica 2D
- Misterio
- Point & Click

---

## Controles

- Estilo **Full Throttle**: click en un objeto/persona abre la **moneda de acciones** (Mirar · Hablar · Usar · Tomar). Mirar y Hablar son distintos.
- En la ruta: hablá con el **vendedor**, tomá el **bolso** (pasa a ser el botón de la esquina; tutorial breve) y recién ahí entrá al pueblo.
- **Bolso**: inventario; seleccioná un ítem y click en el objetivo (`Usar la pelota con el policía`).
- **Máscaras**: segundo click en el slot (o ítem + click en el detective) para equipar.
- Escape: cerrar la moneda / pausa.

El juego está pensado en **horizontal (landscape)**. En tablet/celular escala manteniendo 16:9, con botones e inventario más grandes y márgenes seguros.

---

## Tecnologías

- **Engine**: Godot Engine **4.7**
- **Lenguaje**: GDScript
- **Sistema de diálogos**: **Dialogue Manager 3**
- **Plataforma**: Windows / Linux / Web

---

## Cómo correr el proyecto

### Requisitos
- Godot Engine **4.7**

### Desde el editor
1. Clonar el repositorio
2. Abrir `project.godot` con Godot 4.7
3. Presionar Play

---

## Arquitectura (resumen)

| Autoload | Rol |
|----------|-----|
| `Inventory` | Ítems, selección, persistencia de pickups, catálogo `ItemResource` |
| `StoryFlags` | Flags narrativos, pistas vistas, máscara, paso, caso resuelto |
| `SceneRouter` | Cambio de escena con fade y spawn points |
| `GameManager` | Fachada compatible con mutations de Dialogue Manager + save |
| `AudioManager` | Música |

Interactables comparten `scripts/core/interactable.gd` / `npc_interactable.gd`. Contenido en `content/` (diálogos + ítems); arte/audio en `assets/`; escenas en `scenes/{rooms,actors,ui,systems}/`.

---

## Equipo

- Julian Medrano — Arte / Programación / Narrativa
- Matias Berelejis — Arte / Narrativa
- Camilo Gencarelli — Musica / Diseño sonoro
- Gustavo Orellano — Diseño sonoro
- Tobias Gencarelli — Arte / Narrativa
- Nicolas de la Cruz — Programación

Todos trabajamos haciendo produccion y game design
