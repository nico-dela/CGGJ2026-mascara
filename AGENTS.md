# AGENTS.md — El Caso del Leñador

Aventura gráfica point & click 2D (Córdoba Global Game Jam 2026). Sesión corta: misterio, diálogos, máscaras.

## Stack

- Godot **4.7**, GDScript, renderer GL Compatibility
- Dialogue Manager 3 (`addons/dialogue_manager/` — no editar salvo necesidad)
- Landscape 16:9 (1920×1080 base); touch-friendly

## Arquitectura

| Autoload | Rol |
|----------|-----|
| `GameManager` | Fachada para mutaciones de diálogo + save |
| `StoryFlags` | Flags narrativos, máscara equipada, evidencia |
| `Inventory` | Ítems, selección, pickups persistentes |
| `SceneRouter` | Cambio de escena con fade y spawn ids |
| `InteractionHint` | Texto de verbo al hover |
| `AudioManager` / `DisplayAdapt` / `PauseMenu` | Audio, UI scale, pausa |
| `AdventureUI` | Verb coin + Bolso HUD |

- Interactables: `scripts/core/interactable.gd`, `scripts/core/npc_interactable.gd`
- Diálogos: `content/dialogue/**` (mutations vía `GameManager.*`)
- Ítems: `content/items/*.tres` (`ItemResource`: `ITEM` / `MASCARA`)
- Rooms: `scenes/rooms/room_road.tscn` (ruta) → `room_1` (exterior) → `room_2` (comisaría) / `room_3` (bar)

## Estructura de carpetas

```
autoload/           # singletons
assets/art|audio|video|fonts
content/dialogue|items
scenes/rooms|actors|ui|systems
scripts/core|actors|interactables|ui
ui/balloon/
addons/             # no editar Dialogue Manager
```

## Canon narrativo (MVP)

- La **máscara de oso** convierte en leñador. Portador original = **pescador** → leñador = pescador.
- Objetivo: resolver el caso para **reabastecer caldera y leña**.
- Parte 1: ruta → hablar con **guardia de ruta** → tomar el **bolso** (tutorial UI) → pueblo; hambre → bar; **cartel** fija el objetivo.
- Briefing del caso / huellas: **comisario** en la comisaría (no sabe que el jugador es detective hasta que conversan; ahí pide ayuda → `comisario_briefing`).
- Objetos del bosque aparecen al exponerse el problema ([Why Adventure Games Suck](https://grumpygamer.com/why_adventure_games_suck/) — no solución antes del problema):
  - **Patito** tras el bartender mencionarlo.
  - **Pelota** (+ tronco/hacha como escena) tras el briefing del comisario pidiendo evidencia con huellas.
  - **Máscara oso** tras las **huellas** (el comisario manda a mirar el bosque otra vez).
  - **Hiedra** siempre visible hasta cortarla.
- Pelota → policía → flag **huellas** (“son del cantinero”).
- Con **oso equipado**: Tomar el **hacha** del tronco; **usar hacha con hiedra** → `abrir_paso` (acceso al río).
- Patito → devolver al bar (afecto / foreshadow; **no gate**).
- Exponer bartender: **huellas AND** oso **equipado** + Hablar → pescador se mueve al río (el paso físico lo abre el hacha).
- Final A: máscara al pescador → trato (leña a ratos) → **créditos**.

## Controles / UX

- Estilo **Full Throttle**: click en un hotspot abre la **verb coin** (Mirar / Hablar / Usar / Tomar). **Mirar ≠ Hablar** en NPCs. **Usar** solo se habilita si el hotspot tiene efecto real (no reject).
- En la ruta: el bolso del mundo se **toma** y se convierte en el botón **Bolso** (esquina). Sin bolso no se pueden tomar ítems. Tutorial breve al tomarlo.
- `TownTransition` (pueblo) requiere `hablado_guardia`.
- Inventario en **Bolso**; seleccionar ítem y click en objetivo = usar con…
- Máscara: segundo click en el slot o Usar + click en el detective.
- Puertas / transiciones: click directo. Escape cierra la coin.
- Autoload `AdventureUI`; los `InventoryUI` por room quedan ocultos.

## Convenciones de código

- Estado narrativo en `StoryFlags`; diálogos solo llaman `GameManager.*`.
- Puzzles deben avanzar la historia (Gilbert): objetivo claro, problema antes que solución, eventos conectados al abrir el río.
- Preferir assets existentes o CC0 jam-friendly; no sobre-engineerar.
- Stretch (opcional): máscaras propias de bartender/policía con personalidad.
- No tocar `addons/dialogue_manager/`. No regenerar `build/` salvo que pidan export.
