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

- Interactables: `scripts/interactable.gd`, `scripts/npc_interactable.gd`
- Diálogos: `dialogues/*.dialogue` (mutations vía `GameManager.*`)
- Ítems: `resources/items/*.tres` (`ItemResource`: `ITEM` / `MASCARA`)
- Rooms: `scenes/room_road.tscn` (ruta) → `room_1` (exterior) → `room_2` (comisaría) / `room_3` (bar)

## Canon narrativo (MVP)

- La **máscara de oso** convierte en leñador. Portador original = **pescador** → leñador = pescador.
- Objetivo: resolver el caso para **reabastecer caldera y leña**.
- Parte 1: ruta, **guardia de ruta** (distinto del comisario), hambre → bar; **cartel** fija el objetivo.
- Briefing del caso / huellas: **comisario** en la comisaría.
- Pelota → inventario → policía → flag **huellas** (“son del cantinero”; el jugador deduce).
- Patito → inventario → devolver al bar (afecto / foreshadow; **no gate**).
- Exponer bartender requiere **huellas AND** detective con oso **equipado** + hablarle.
- Al exponer: abre paso al río + pescador se mueve al río.
- Final A: máscara al pescador → trato (leña a ratos, sin vivir solo como leñador) → **créditos**.
- Hacha/tronco = escenografía / recuerdo con oso; **no** abre caminos.

## Controles

- Click izquierdo / touch: caminar e interactuar (estilo Monkey Island).
- Inventario: seleccionar ítem → usarlo en NPC/objeto.
- Máscara en sí: click cerca del detective con máscara seleccionada (equipar/desequipar). Sprite → leñador si lleva oso.
- **No** menú de click derecho / verb coin.
- Hints de verbo claros y touch-friendly.

## Convenciones de código

- Estado narrativo en `StoryFlags`; diálogos solo llaman `GameManager.*`.
- Puzzles deben avanzar la historia (Gilbert): objetivo claro, problema antes que solución, eventos conectados al abrir el río.
- Preferir assets existentes o CC0 jam-friendly; no sobre-engineerar.
- Stretch (opcional): máscaras propias de bartender/policía con personalidad.
- No tocar `addons/dialogue_manager/`. No regenerar `build/` salvo que pidan export.
