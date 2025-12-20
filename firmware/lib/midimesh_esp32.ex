# This file is part of midiMESH
#
# Copyright 2025 Nanas Sound OÜ <asep@nanassound.com>

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule MidimeshEsp32 do
  alias MidimeshEsp32.WiFi
  alias MidimeshEsp32.Knob
  alias MidimeshEsp32.MidiOps
  alias MidimeshEsp32.Switch

  @compile {:no_warn_undefined, [GPIO]}

  # built-in LED
  @led_pin 8

  # Switch for selecting AP mode or STA mode
  @switch_pins {10}

  # knob analog pin configuration
  @knob_pins {0, 1, 2, 3, 4}
  # knob midi CC number in the same order as the pin
  @knob_midi_cc_number {75, 76, 77, 78, 79}
  # knob identifier in the same order as the pin
  @knob_ids {:slide_pot, :pot_1, :pot_2, :pot_3, :pot_4}
  # knob rotation direction in the same order as the pin
  # :cw = clockwise (normal), :ccw = counter-clockwise (inverted for PCB fix)
  @knob_directions {:cw, :ccw, :ccw, :ccw, :ccw}

  # UDP Configuration
  # Broadcast it!
  @udp_target_ip {255, 255, 255, 255}
  @udp_target_port 4000

  # MIDI Configuration
  # Channel 1 (0-indexed)
  @midi_channel 0

  def start() do
    # Setup LED indicator pin
    GPIO.set_pin_mode(@led_pin, :output)

    # Start and opening UDP socket
    udp_sender_pid = spawn(fn -> start_udp_sender() end)

    # Give the UDP sender time to initialize
    Process.sleep(100)

    # Start and activate all knobs
    Knob.activate_knobs(@knob_pins)

    Knob.spawn_knobs_reading(
      @knob_pins,
      @knob_ids,
      @knob_directions,
      udp_sender_pid
    )

    # Start and activate all switches
    Switch.activate_switches(@switch_pins)

    # Decide between AP mode or STA mode.
    # When the switch is ON, it should become AP mode
    case MidimeshEsp32.Switch.read_state(elem(@switch_pins, 0)) do
      :low ->
        {:ok, config} =
          WiFi.get_config(:ap_mode)

        IO.puts("AP MODE CONFIG: #{inspect(config)}")
        WiFi.wait_for_mode(:ap_mode, config, &ap_mode_callback/0)

      :high ->
        {:ok, config} =
          WiFi.get_config(:sta_mode)

        WiFi.wait_for_mode(:sta_mode, config, &sta_mode_callback/1)
    end

    # Loop the main process forever
    wait_forever()
  end

  # Since this MIDI controller works exclusively via WiFi
  # Then we will do everything after this device get IP address.
  # This is for STA mode
  defp sta_mode_callback(ip_info) do
    IO.puts("Got IP: #{inspect(ip_info)}")

    # Start LED blinking in a separate process.
    # It acts as an indicator that this device successfully connected to the WiFi
    # and get an IP address
    spawn(fn -> blinking_led(@led_pin, :low) end)
  end

  # If the device in AP mode, we will start from here
  defp ap_mode_callback do
    spawn(fn -> blinking_led(@led_pin, :low, 5000) end)
  end

  defp blinking_led(pin, level, timer \\ 1000) do
    GPIO.digital_write(pin, level)
    Process.sleep(timer)
    blinking_led(pin, toggle(level), timer)
  end

  defp toggle(:high), do: :low
  defp toggle(:low), do: :high

  defp wait_forever do
    receive do
    end
  end

  # UDP Sender Functions
  defp start_udp_sender do
    IO.puts("Starting UDP sender...")

    case :gen_udp.open(0) do
      {:ok, socket} ->
        IO.puts("UDP socket opened successfully")
        udp_sender_loop(socket)

      {:error, reason} ->
        IO.puts("Failed to open UDP socket: #{inspect(reason)}")
    end
  end

  defp udp_sender_loop(socket) do
    receive do
      {:knob_value_with_index, knob_index, knob_id, knob_value} ->
        IO.puts(
          "Knob changed - Index: #{knob_index}, ID: #{knob_id}, Value: #{inspect(knob_value)}"
        )

        {_raw_value, _voltage, midi_value} = knob_value

        status_byte = 0xB0 + @midi_channel
        cc_number = elem(@knob_midi_cc_number, knob_index)
        cc_data = <<status_byte, cc_number, midi_value>>
        MidiOps.send_midi(socket, cc_data, @udp_target_ip, @udp_target_port)

        udp_sender_loop(socket)

      other ->
        IO.puts("Received unexpected message: #{inspect(other)}")
        udp_sender_loop(socket)
    end
  end
end
