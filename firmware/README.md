# midiMESH ESP32

MIDI controller over UDP network using AtomVM on ESP32-C3. This project is tested with this board ESP32-C3 from SuperMini.

## YouTube Demo

[Controlling Arturia Pigments](https://www.youtube.com/shorts/djaUUPquI_E)

[Knob Control in Ableton Live](https://www.youtube.com/shorts/GX_Sy0ogvio)

## Features

- Supports multiple analog potentiometers with concurrent processing (default: 2 knobs)
- Sends MIDI CC (Control Change) messages over UDP
- Modular architecture with separate modules for Knob, MIDI operations, and Config
- LED indicator for WiFi connection status
- Runs on ESP32-C3 with AtomVM
- Broadcasts to local network on port 4000

## Requirements

- ESP32-C3 board (tested with SuperMini)
- [AtomVM v0.6.6](https://github.com/atomvm/AtomVM/releases/tag/v0.6.6) flashed on the device
- Elixir with [ExAtomVM](https://github.com/atomvm/ExAtomVM)
- esptool.py for flashing

## Installing AtomVM on ESP32-C3

1. Run `mix deps.get` to get all dependencies.
2. Run `mix atomvm.esp32.install` to install and flash the latest stable releases of AtomVM.

**Important for ESP32-C3**: The flash offset in `mix.exs` must be set to `0x250000` to match the AtomVM partition layout.

## Hardware Setup

- **Potentiometers**: Connect analog potentiometers (tested with B10K) to:
  - Knob 1: GPIO 0
  - Knob 2: GPIO 1
- **LED**: Status LED on GPIO 8 (blinks when connected to WiFi)

## Configuration

### WiFi Credentials

1. Copy `lib/config_example.ex` to `lib/config.ex`
2. Rename the module from `ConfigExample` to `MMConfig`
3. Fill in your WiFi credentials:

```elixir
defmodule MMConfig do
  def ssid_name, do: "your_ssid"
  def ssid_password, do: "your_password"
end
```

### MIDI Settings

Edit `lib/midimesh_esp32.ex`:

```elixir
# Hardware pins - Add/remove pins as tuples to support more/fewer knobs
@knob_pins {0, 1}    # GPIO pins for potentiometers (Knob 1, Knob 2, ...)

# LED indicator
@led_pin 8           # GPIO pin for status LED

# Network
@udp_target_ip {255, 255, 255, 255}  # Broadcast or specific IP
@udp_target_port 4000

# MIDI - CC numbers map 1:1 with knob pins by position
@knob_midi_cc_number {16, 17}  # CC numbers for each knob
@midi_channel 0                # Channel 0 in code = channel 1 in DAW (n+1)
```

**Adding more knobs**: Simply extend both tuples. For example, to add a 3rd knob:
```elixir
@knob_pins {0, 1, 2}
@knob_midi_cc_number {16, 17, 18}
```

## Build & Flash

```bash
mix atomvm.packbeam
mix atomvm.esp32.flash --port /dev/tty.usbmodem1101 # Adjust with your actual port
```

## Receiver

Use the companion [desktop_receiver](https://github.com/nanassound/midimesh_desktop_receiver) project to receive UDP MIDI and forward to a virtual MIDI port (e.g., IAC Driver on macOS).

## License

[Apache 2.0 license](LICENSE.md)
