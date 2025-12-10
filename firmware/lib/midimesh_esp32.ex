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
  @compile {:no_warn_undefined, [GPIO]}
  # built-in LED
  @led_pin 8

  # knob analog pin configuration
  @knob_pins {0, 1}
  # knob midi CC number in the same order as the pin
  @knob_midi_cc_number {16, 17}

  # UDP Configuration
  # Broadcast it!
  @udp_target_ip {255, 255, 255, 255}
  @udp_target_port 4000

  # MIDI Configuration
  # Channel 1 (0-indexed)
  @midi_channel 0

  def start() do
    GPIO.set_pin_mode(@led_pin, :output)

    number_of_knobs = tuple_size(@knob_pins)
    Knob.activate_knobs(@knob_pins, number_of_knobs)

    config = [
      sta: [
        # SSID name
        ssid: MMConfig.ssid_name(),
        # SSID password
        psk: MMConfig.ssid_password(),
        connected: &connected/0,
        got_ip: &got_ip/1,
        disconnected: &disconnected/0,
        dhcp_hostname: "midimesh_esp32"
      ]
    ]

    case :network.start(config) do
      {:ok, pid} ->
        IO.puts("Network started with pid: #{inspect(pid)}")

      {:error, reason} ->
        IO.puts("Failed to start network: #{inspect(reason)}")
        {:error, reason}
    end

    # Loop the main process forever
    wait_forever()
  end

  defp connected do
    IO.puts("Connected to WiFi!")
  end

  # Since this MIDI controller works exclusively via WiFi
  # Then we will do everything after this device get IP address
  defp got_ip(ip_info) do
    IO.puts("Got IP: #{inspect(ip_info)}")

    # Start LED blinking in a separate process.
    # It acts as an indicator that this device successfully connected to the WiFi
    # and get an IP address
    spawn(fn -> blinking_led(@led_pin, :low) end)

    # Start udp sender process
    spawn(fn -> start_udp_sender() end)
  end

  defp disconnected do
    IO.puts("Disconnected from WiFi")
  end

  defp blinking_led(pin, level) do
    GPIO.digital_write(pin, level)
    Process.sleep(1000)
    blinking_led(pin, toggle(level))
  end

  defp toggle(:high), do: :low
  defp toggle(:low), do: :high

  defp spawn_knobs_reading_process(_pins, 0, nil), do: :ok

  defp spawn_knobs_reading_process(pins, number_of_knobs, socket) when number_of_knobs > 0 do
    current_knob_index = number_of_knobs - 1
    knob_pin = elem(pins, current_knob_index)
    cc_number = elem(@knob_midi_cc_number, current_knob_index)

    spawn(fn -> read_knob(knob_pin, socket, nil, cc_number) end)

    # Repeat until all knobs get a process
    spawn_knobs_reading_process(pins, number_of_knobs - 1, socket)
  end

  defp read_knob(pin, socket, prev_cc_val, cc_number) do
    knob_val = Knob.read_analog(pin)

    current_cc_val =
      case knob_val do
        {:ok, {_, _, cc_val}} ->
          # Only send if value changed
          if cc_val != prev_cc_val do
            status_byte = 0xB0 + @midi_channel
            cc_data = <<status_byte, cc_number, cc_val>>
            MidiOps.send_midi(socket, cc_data, @udp_target_ip, @udp_target_port)
          end

          cc_val

        {:error, reason} ->
          IO.puts("Error knob: #{inspect(reason)}")
          prev_cc_val
      end

    Process.sleep(15)
    read_knob(pin, socket, current_cc_val, cc_number)
  end

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

        number_of_knobs = tuple_size(@knob_pins)
        spawn_knobs_reading_process(@knob_pins, number_of_knobs, socket)

      {:error, reason} ->
        IO.puts("Failed to open UDP socket: #{inspect(reason)}")
    end
  end
end
