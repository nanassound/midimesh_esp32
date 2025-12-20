# midiMESH ESP32

Open-source modular MIDI devices ecosystem over WiFi using ESP32-C3 and AtomVM. Control your DAW and devices wirelessly with various hardware controllers.

**Key Features:**
- MIDI CC messages over UDP/WiFi
- Concurrent multi-knob support with Elixir processes
- Operational in AP mode or STA mode
- Modular hardware designs (Eurorack-compatible)
- Runs AtomVM (Erlang VM) on ESP32-C3

**Demos:**
- [Controlling Arturia Pigments](https://www.youtube.com/shorts/djaUUPquI_E)
- [Knob Control in Ableton Live](https://www.youtube.com/shorts/GX_Sy0ogvio)

## Project Structure

```
midimesh_esp32/
├── firmware/     # Elixir/AtomVM firmware for ESP32-C3
└── hardware/     # KiCad PCB design files for midiMESH devices
```

This repository contains both the firmware and hardware designs for the midiMESH ecosystem.

- **Firmware**: See [`firmware/`](firmware/) for the Elixir code that runs on the ESP32-C3. Detailed build, flash, and configuration instructions are in [`firmware/README.md`](firmware/README.md).
- **Hardware**: See [`hardware/`](hardware/) for various midiMESH device designs. Each subdirectory contains KiCad design files for a specific controller.

## Firmware

The firmware is written in Elixir and runs on [AtomVM](https://github.com/atomvm/AtomVM), a lightweight Erlang VM for embedded systems.

**Features:**
- Supports multiple analog potentiometers with concurrent processing
- Sends MIDI CC (Control Change) messages over UDP
- LED indicator for WiFi connection status
- Broadcasts to local network on port 4000
- Modular architecture with separate modules for Knob, Switch, MIDI operations, and Config

**Hardware pins** (configurable in code):
- Knob 1: GPIO 0
- Knob 2: GPIO 1
- LED: GPIO 8

For complete setup instructions, WiFi configuration, building, and flashing, see **[`firmware/README.md`](firmware/README.md)**.

## Hardware

The midiMESH ecosystem includes various Eurorack-compatible MIDI controller designs, each tailored for different control needs.

**Available Designs:**
- **Slide & Twist**: Controller with knobs and slide potentiometer

**Design Files:**
- KiCad v9.0 schematics and PCB layouts
- Location: [`hardware/`](hardware/)
- Each device has its own subdirectory with complete design files

For detailed component information and specifications for each controller, see [`hardware/README.md`](hardware/README.md).

The design files are provided as-is for viewing, modification, and manufacturing.

## Getting Started

### Prerequisites

**For Firmware:**
- ESP32-C3 board (tested with SuperMini)
- [AtomVM v0.6.6](https://github.com/atomvm/AtomVM/releases/tag/v0.6.6)
- Elixir with [ExAtomVM](https://github.com/atomvm/ExAtomVM)
- esptool.py for flashing

**For Hardware:**
- KiCad 9.0 or later to view/edit design files

### Quick Start

1. **Flash firmware**: Follow the detailed instructions in [`firmware/README.md`](firmware/README.md) to configure WiFi, build, and flash the ESP32-C3.
2. **View hardware designs**: See [`hardware/README.md`](hardware/README.md) for available midiMESH devices. Open the KiCad project files to explore or modify the PCB designs.
3. **Receive MIDI**: Use the companion [midiMESH desktop receiver](https://github.com/nanassound/midimesh_desktop_receiver) to receive UDP MIDI and forward it to a virtual MIDI port for use in your DAW.

## Related Projects

- **[midimesh_desktop_receiver](https://github.com/nanassound/midimesh_desktop_receiver)**: Desktop application that receives UDP MIDI messages from the ESP32 and forwards them to a virtual MIDI port (e.g., IAC Driver on macOS).

## License

This project is dual-licensed:

### Firmware License

The firmware (in [`firmware/`](firmware/)) is licensed under the **Apache 2.0 license**.

See [`firmware/LICENSE.md`](firmware/LICENSE.md) for full license text.

### Hardware License

The hardware design (in [`hardware/`](hardware/)) is licensed under the **CERN Open Hardware License v2 - Weakly Reciprocal (CERN-OHL-W)**.

See [`hardware/LICENSE.md`](hardware/LICENSE.md) for full license text.

### Derivative Works Guidelines

Both licenses allow you to freely use, study, modify, and distribute this project and create derivative works.

**Important:** You must **NOT** use the "Nanas Sound" name, logo, or any other Nanas Sound identifiers in your derivative works. Nanas Sound is a business name of [Nanas Sound OÜ](https://ariregister.rik.ee/est/company/16028176/Nanas-Sound-OÜ).

**Examples of acceptable naming:**
- **Correct**: "Strawberry Field - MIDIYummy"
- **Incorrect**: "Nanas Sound's midiMESH" or "Based on Nanas Sound midiMESH"

We encourage you to create and share your own versions of this project while respecting our trademark.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to open an issue or submit a pull request.

---

**Copyright 2025 Nanas Sound OÜ**
