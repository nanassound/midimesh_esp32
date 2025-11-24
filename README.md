# MidiMesh ESP32

MIDI controller over UDP network using AtomVM on ESP32-C3. This project is tested with this board ESP32-C3 from SuperMini.

## YouTube Demo

[Controlling Arturia Pigments](https://www.youtube.com/shorts/djaUUPquI_E)

## Features

- Reads analog potentiometer values and sends MIDI CC (Control Change) messages over UDP
- Modular architecture with separate modules for Knob, MIDI operations, and Config
- LED indicator for WiFi connection status
- Runs on ESP32-C3 with AtomVM
- Broadcasts to local network on port 4000

## Requirements

- ESP32 (tested on ESP32-C3)
- [AtomVM](https://atomvm.org) flashed on the device
- Elixir with [ExAtomVM](https://github.com/atomvm/ExAtomVM)

## Hardware Setup

- **Potentiometer**: Connect a potentiometer (tested with B10K) to GPIO 0
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
# Hardware pins
@knob_pin 0          # GPIO pin for potentiometer
@led_pin 8           # GPIO pin for status LED

# Network
@udp_target_ip {255, 255, 255, 255}  # Broadcast or specific IP
@udp_target_port 4000

# MIDI
@midi_channel 0      # Channel 0 in code means channel 1 in DAW/hardware (n+1)
```

**Note**: CC number is currently hardcoded to 16 in the `read_knob/3` function.

## Build & Flash

```bash
mix deps.get
mix atomvm.packbeam
mix atomvm.esp32.flash --port /dev/tty.usbmodem1101 # Adjust with your actual port
```

## Receiver

Use the companion [desktop_receiver](https://github.com/nanassound/midimesh_desktop_receiver) project to receive UDP MIDI and forward to a virtual MIDI port (e.g., IAC Driver on macOS).

## License

[MIT](LICENSE.md)
