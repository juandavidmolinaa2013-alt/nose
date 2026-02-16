# Roblox chat commands (Luau)

## 1) Dar tool por chat
Usa `ChatGiveTool.server.lua` en **ServerScriptService** para comandos como:
- `/Give Card`
- `/Give My Cool Tool`

El script ahora:
- busca tools sin importar mayúsculas/minúsculas,
- soporta nombres con espacios,
- y acepta alias por `Attribute` llamado `GiveAliases` (string con comas) para que siga funcionando aunque renombres la tool.

## 2) Volar por chat + animaciones por ID
Para volar por comando y usar dos animaciones (idle/move) necesitas **2 scripts**:

1. `ChatFly.server.lua` en **ServerScriptService**.
2. `FlyClient.local.lua` en **StarterPlayer > StarterPlayerScripts**.

### Comandos
- `/Fly` activa vuelo.
- `/Unfly` desactiva vuelo.

### Configuración de animaciones (por ID)
En `FlyClient.local.lua` reemplaza:
- `FLY_IDLE_ANIMATION_ID`
- `FLY_MOVE_ANIMATION_ID`

Ejemplo de formato:
- `rbxassetid://1234567890`

### Controles durante el vuelo
- PC: WASD para moverte, `Space` para subir, `LeftControl` para bajar.
- Celular: joystick de Roblox para moverte horizontalmente.
- Celular: mira la cámara hacia arriba para subir y hacia abajo para bajar.

> Nota: agrega tu `UserId` en `ADMINS` de `ChatFly.server.lua` para permitir el comando.


## 3) Chase theme por distancia (layers + fade rápido)
Usa `ChaseThemeScript.server.lua` dentro del modelo del NPC (por ejemplo `SCP096`).

Requisitos dentro del modelo:
- `HumanoidRootPart`
- `Sound` llamado `ChaseSound`

Este script:
- usa layers por distancia con rangos 2-15, 15-29, 29-43 y 43-158,
- hace fade al cambiar de layer (acercarse/alejarse),
- hace fade al repetir el loop de la misma layer para evitar corte brusco,
- y silencia temporalmente cuando la distancia cambia muy rápido, hasta estabilizarse en una layer.


## 4) Traspasar paredes por chat (noclip)
Usa `ChatNoclip.server.lua` en **ServerScriptService**.

### Comandos
- Comandos aceptados para activar: `/Noclip`, `noclip`, `!noclip`, `/e noclip`.
- Comandos aceptados para desactivar: `/Clip`, `clip`, `!clip`, `/e clip`.

Mejora anti-choques:
- Usa `CollisionGroup` dedicado (`NoClipPlayers`) + `CanCollide=false` y refuerzo continuo para evitar que vuelvas a chocar con cosas al azar.
- Incluye anti-caída (`VectorForce`) para que no te vayas al vacío mientras noclip está activo.

> Recuerda agregar tu `UserId` en `ADMINS` o usar `ALLOW_ALL_PLAYERS_FOR_TESTING=true` solo para pruebas.


## 5) Correr en celular + L2 en PlayStation
Usa `MobilePlayStationSprint.local.lua` en **StarterPlayer > StarterPlayerScripts**.

Comportamiento:
- En **celular** aparece un botón "RUN" (mantener presionado para correr).
- En **PlayStation/gamepad** mantén presionado **L2** para correr.

Configurable en script:
- `NORMAL_SPEED`
- `SPRINT_SPEED`


## 6) Correr toggle en celular con StarterGui/Correr/Run
Estructura UI requerida en **StarterGui**:
- `Correr` (ScreenGui)
  - `Run` (ImageButton)

Script:
- Usa `CorrerToggleMobile.local.lua` como **hijo de `Run`**:
  - `StarterGui > Correr > Run > LocalScript`

Comportamiento:
- Solo funciona en celular/touch.
- Toca una vez `Run` para correr.
- Vuelve a tocar `Run` para regresar a velocidad normal.
- Reproduce animación de correr cuando está activado y el personaje se mueve (configura `RUN_ANIMATION_ID`).


## 7) Cooldown de salto (2 segundos)
Usa `JumpCooldown.local.lua` en **StarterPlayer > StarterPlayerScripts**.

Comportamiento:
- El primer salto funciona normal.
- Después de cada salto, el siguiente solo se permite tras **2 segundos**.
- Ajusta el valor en `JUMP_COOLDOWN` si quieres otro tiempo.


## 8) Reunir jugadores automáticamente al actualizar el juego
Usa `AutoRejoinOnUpdate.server.lua` en **ServerScriptService**.

Qué hace:
- Detecta cuando un servidor quedó en versión vieja.
- Reúne a los jugadores de ese servidor en uno nuevo (latest build) con `TeleportAsync`.

Configurar en script:
- Cambia `BUILD_ID` en cada publicación (ejemplo: `2026-02-15_01`).


## 9) SCP-096 simplificado (chase + getting up FX)
Scripts:
- `SCP096ChaseSimplified.server.lua` -> poner dentro del modelo de SCP-096.
- `SCP096GettingUpEffects.client.lua` -> poner en `StarterPlayer > StarterPlayerScripts`.

Qué hace:
- Persigue al jugador más cercano con animaciones básicas (idle/run/getting up).
- Cuando inicia `getting up`, muestra `TextLabel` + `ImageLabel` y hace temblar cámara del jugador objetivo.
- Al morir el jugador, los efectos se limpian automáticamente.

Configurar:
- `GETTING_UP_ANIMATION_ID`, `RUN_ANIMATION_ID`, `IDLE_ANIMATION_ID`
- En payload del server: `image = "rbxassetid://..."`


## 10) Efecto "¡You see his Face!" sin cambiar tu script viejo de SCP-096
Usa estos 2 scripts (addon, no reemplazan tu script antiguo):
- `SCP096GettingUpFXBridge.server.lua` dentro del modelo de SCP-096.
- `SCP096FaceEffects.client.lua` en `StarterPlayer > StarterPlayerScripts`.

Qué hace:
- Detecta cuando se reproduce la animación de `GettingUp` (usando los mismos IDs que ya tienes).
- Muestra un `ImageLabel` arriba de un `TextLabel` rojo con texto **"¡You see his Face!"**.
- Hace temblar cámara y limpia todo cuando termina o cuando el jugador muere.

Configurar:
- En `SCP096GettingUpFXBridge.server.lua`, pon tus IDs reales en `GETTING_UP_ANIMATION_IDS`.
- En `SCP096FaceEffects.client.lua`, configura `IMAGE_ID`.


## 11) Trigger por Part: mostrar "VerCara" + "ImagenCalavera" y shake
Scripts:
- `PartTouchFaceEffect.server.lua` -> dentro de la Part que se toca.
- `PartTouchFaceEffect.client.lua` -> `StarterPlayer > StarterPlayerScripts`.

Requisitos de GUI ya creados (invisibles por defecto):
- `Effect096` (ScreenGui)
  - `VerCara` (TextLabel)
  - `ImagenCalavera` (ImageLabel)

Comportamiento:
- Al tocar la Part, ambos se ponen visibles por 3 segundos.
- Se aplica camera shake leve durante ese tiempo.
- Se ocultan y limpian al terminar o al morir el jugador.
- Cooldown global del trigger: si un jugador lo activa, nadie puede volver a activarlo hasta que ese jugador muera.

Ajuste fácil del shake (client script):
- `EFFECT_DURATION`
- `SHAKE_INTENSITY`
- `SHAKE_Z_INTENSITY`


## 12) Linterna en la cabeza (toggle con F)
Scripts:
- `HeadFlashlight.server.lua` -> `ServerScriptService`
- `HeadFlashlight.client.lua` -> `StarterPlayer > StarterPlayerScripts`

Comportamiento:
- Cada jugador emite luz desde la cabeza (usa `Attachment` + `SpotLight` + `PointLight` para que se vea mejor).
- Presiona `F` para encender/apagar.


## 13) Morph a SCP-096 al tocar Part "096" + animaciones por estado
Script:
- `SCP096MorphByTouch.server.lua` -> `ServerScriptService`

Requisitos:
- Part en `Workspace` llamada `096`
- Rig `SCP-096` (recomendado en `ServerStorage`) con `Humanoid` y `HumanoidRootPart`

Animaciones configurables en script (pon TUS ids):
- `WALK_ANIMATION_ID` (caminar)
- `IDLE_ANIMATION_ID` (idle normal)
- `QUIETO_1_ANIMATION_ID` (Quieto 1)
- `QUIETO_2_ANIMATION_ID` (Quieto 2)
- `QUIETO_3_ANIMATION_ID` (Quieto 3)

Lógica de quieto:
- Si queda quieto por más de 1 minuto (`QUIETO_SEQUENCE_DELAY = 60`), se cancela `idle`.
- Se reproducen en orden: Quieto 1 -> Quieto 2 -> Quieto 3.
- Al terminar las 3, vuelve a `idle`.
- Incluye anti-deslizamiento: cuando no hay input de movimiento, frena deriva horizontal del `HumanoidRootPart` para rigs grandes.

Notas para que sí funcione:
- La Part debe llamarse exactamente `096` y estar en `Workspace`.
- El rig debe llamarse exactamente `SCP-096` y tener `Humanoid` + `HumanoidRootPart`.

Fix de cámara para morph:
- Si la cámara se queda congelada tras convertirte, agrega `SCP096MorphCameraFix.client.lua` en `StarterPlayer > StarterPlayerScripts` (ahora también escucha señal del server para rebind inmediato).

