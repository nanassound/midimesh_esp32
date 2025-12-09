# midiMESH Hardware Designs

This directory contains KiCad design files for various midiMESH controllers. Each controller is a Eurorack-compatible MIDI device that works with the midiMESH firmware.

## Available Controllers

### Slide & Twist

**Description:** A versatile MIDI controller featuring both rotary knobs and a slide potentiometer for expressive control.

**Key Components:**
- ESP32-C3 SuperMini microcontroller
- 4 potentiometers (10k, B10K) - rotary knobs
- 1 slide potentiometer (PTL30-19G1-103B2)
- 1 SPDT sub-miniature toggle switch
- 1 LED (status indicator)
- 1 resistor (LED current limiting)
- Eurorack 16-pin shrouded power connector
- Pin headers for ESP32-C3 SuperMini

**Power Requirements:**
+5V from USB-C, Eurorack power header (J2), or adding battery to the power connector (J1)

**Design Files:**
- Location: [`slide_and_twist/`](slide_and_twist/)
- Schematic: `slide_and_twist.kicad_sch`
- PCB Layout: `slide_and_twist.kicad_pcb`
- Project File: `slide_and_twist.kicad_pro`

**KiCad Version:** 9.0

**Last Updated:** 2025-12-06

## Design Notes

All midiMESH controllers share common features:
- Eurorack form factor and power compatibility
- ESP32-C3 based for WiFi connectivity
- Designed to work with the midiMESH firmware (see [`firmware/`](../firmware/))
- Status LED for connection indication
- Modular and expandable design

## Using the Design Files

### Viewing and Editing

1. Install [KiCad 9.0](https://www.kicad.org/download/) or later
2. Open the `.kicad_pro` file in the respective controller directory
3. View schematics (`.kicad_sch`) and PCB layout (`.kicad_pcb`)

### Manufacturing

The design files are ready for PCB manufacturing. You can:
- Export Gerber files from KiCad for PCB fabrication
- Export BOM (Bill of Materials) for component ordering
- Export pick-and-place files for assembly (if needed)

**Note:** Assembly and manufacturing instructions are not provided. Users are expected to have basic PCB manufacturing and assembly knowledge.

## License

All hardware designs in this directory are licensed under the **CERN Open Hardware License v2 - Permissive (CERN-OHL-P)**.

Copyright 2025 Nanas Sound OÜ

See [`LICENSE.md`](LICENSE.md) for full license text.

### Derivative Works

You are free to modify and create derivative works. However, you must **NOT** use the "Nanas Sound" name, logo, or identifiers in your derivatives. See the main [project README](../README.md#derivative-works-guidelines) for details.
