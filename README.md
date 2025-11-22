# MidiMesh ESP32

MIDI controller over UDP network using AtomVM on ESP32-C3. This project is tested with this board ESP32-C3 from SuperMini.

## Features for proof-of-concept

- Sends MIDI 1.0 messages (random note On/Off) over UDP
- Runs on ESP32 with AtomVM
- Broadcasts to local network on port 4000

## Requirements

- ESP32 (tested on ESP32-C3)
- [AtomVM](https://atomvm.org) flashed on the device
- Elixir with [ExAtomVM](https://github.com/atomvm/ExAtomVM)

## Configuration

Edit `lib/midimesh_esp32.ex`:

```elixir
# WiFi
ssid: "your_ssid"
psk: "your_password"

# MIDI
@udp_target_ip {255, 255, 255, 255}  # Broadcast or specific IP
@udp_target_port 4000
@midi_channel 0      # Channel 0 in code means channel 1 in DAW/hardware (n+1)
@min_note 48         # C3
@max_note 71         # B4
```

## Build & Flash

```bash
mix deps.get
mix atomvm.packbeam
mix atomvm.esp32.flash --port /dev/tty.usbmodem1101 # Adjust with your actual port
```

## Receiver

Use the companion `desktop_receiver` project to receive UDP MIDI and forward to a virtual MIDI port (e.g., IAC Driver on macOS).

## License

[MIT](LICENSE.md)
