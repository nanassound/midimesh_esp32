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

  # Switch for selecting AP mode or STA mode
  @switch_pins {10}

  # knob analog pin configuration
  @knob_pins {0, 1, 2, 3, 4}
  # knob midi CC number in the same order as the pin
  @knob_midi_cc_number {75, 76, 77, 78, 79}

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
    MidimeshEsp32.Knob.activate_knobs(@knob_pins, number_of_knobs)

    number_of_switches = tuple_size(@switch_pins)
    MidimeshEsp32.Switch.activate_switches(@switch_pins, number_of_switches)

    # Decide between AP mode or STA mode.
    # When the switch is ON, it should become AP mode
    config =
      case MidimeshEsp32.Switch.read_state(elem(@switch_pins, 0)) do
        :low ->
          {:ok, config} =
            MidimeshEsp32.WiFi.get_config(:ap_mode,
              ap_started: &ap_started/0
            )

          config

        :high ->
          {:ok, config} =
            MidimeshEsp32.WiFi.get_config(:sta_mode,
              got_ip: &got_ip/1
            )

          config
      end

    case :network.start(config) do
      {:ok, network_pid} ->
        # Wait the device to settle down with the network initialization
        Process.sleep(5000)
        IO.puts("Network PID: #{inspect(network_pid)}")

      {:error, reason} ->
        IO.puts("Failed to start network: #{inspect(reason)}")
        {:error, reason}
    end

    # Loop the main process forever
    wait_forever()
  end

  # Since this MIDI controller works exclusively via WiFi
  # Then we will do everything after this device get IP address.
  # This is for STA mode
  defp got_ip(ip_info) do
    IO.puts("Got IP: #{inspect(ip_info)}")

    # Start LED blinking in a separate process.
    # It acts as an indicator that this device successfully connected to the WiFi
    # and get an IP address
    spawn(fn -> blinking_led(@led_pin, :low) end)

    # Start udp sender process
    spawn(fn -> start_udp_sender() end)
  end

  # If the device in AP mode, we will start from here
  defp ap_started do
    # In AP mode, the led will constantly ON to give visual differentiation
    GPIO.digital_write(@led_pin, :low)

    # Start udp sender process
    spawn(fn -> start_udp_sender() end)
  end

  defp blinking_led(pin, level) do
    GPIO.digital_write(pin, level)
    Process.sleep(1000)
    blinking_led(pin, toggle(level))
  end

  defp toggle(:high), do: :low
  defp toggle(:low), do: :high

  defp spawn_knobs_reading_process(_pins, 0, _socket), do: :ok

  defp spawn_knobs_reading_process(pins, number_of_knobs, socket) when number_of_knobs > 0 do
    current_knob_index = number_of_knobs - 1
    knob_pin = elem(pins, current_knob_index)
    cc_number = elem(@knob_midi_cc_number, current_knob_index)

    spawn(fn -> read_knob(knob_pin, socket, nil, cc_number) end)

    # Repeat until all knobs get a process
    spawn_knobs_reading_process(pins, number_of_knobs - 1, socket)
  end

  defp read_knob(pin, socket, prev_cc_val, cc_number) do
    knob_val = MidimeshEsp32.Knob.read_analog(pin)

    current_cc_val =
      case knob_val do
        {:ok, {_, _, cc_val}} ->
          # Only send if value changed
          if cc_val != prev_cc_val do
            status_byte = 0xB0 + @midi_channel
            cc_data = <<status_byte, cc_number, cc_val>>
            MidimeshEsp32.MidiOps.send_midi(socket, cc_data, @udp_target_ip, @udp_target_port)
          end

          cc_val

        {:error, reason} ->
          IO.puts("Error knob: #{inspect(reason)}")
          prev_cc_val
      end

    Process.sleep(50)
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
