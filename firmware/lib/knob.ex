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
defmodule MidimeshEsp32.Knob do
  @moduledoc """
  Knob is a module to abstract the reading of knob component attached to the microcontroller.
  It can be an analog potentiometer or rotary encoder.

  Currently it only supports analog potentiometer.
  """

  @doc """
  Activate GPIO for multiple knobs based on the configuration.
  """
  def activate_knobs(pins) do
    number_of_knobs = tuple_size(pins)
    do_activate_knobs(pins, number_of_knobs)
  end

  defp do_activate_knobs(_pins, 0), do: :ok

  defp do_activate_knobs(pins, number_of_knobs) when number_of_knobs > 0 do
    current_knob_index = number_of_knobs - 1
    knob_pin = elem(pins, current_knob_index)

    # Initialize the knob pin
    :esp_adc.start(knob_pin)

    # Loop for the next knob
    do_activate_knobs(pins, current_knob_index)
  end

  @doc """
  Create multiple processes for reading the knob value.
  Parameters:
    - pins is all pins attached to the potentiometer
    - knob_ids is used for adding the id to each processes
    - knob_directions is the rotation direction for each knob (:cw or :ccw)
    - destination_pid is what PID the knob value to be sent
  """
  def spawn_knobs_reading(pins, knob_ids, knob_directions, destination_pid)
      when tuple_size(pins) === tuple_size(knob_ids) and
             tuple_size(pins) === tuple_size(knob_directions) do
    number_of_knobs = tuple_size(pins)
    do_spawn_knobs_reading(pins, knob_ids, knob_directions, number_of_knobs, destination_pid)
  end

  def spawn_knobs_reading(pins, knob_ids, knob_directions, _destination_pid) do
    {:error,
     {:size_mismatch, tuple_size(pins), tuple_size(knob_ids), tuple_size(knob_directions)}}
  end

  def spawn_knobs_reading(_pins, _knob_ids, _knob_directions, nil) do
    {:error,
     {:no_destination_pid,
      "Nothing to do without any destination PID to send the value of knobs."}}
  end

  # Done spawning the process
  defp do_spawn_knobs_reading(_pins, _knob_ids, _knob_directions, 0, _destination_pid), do: :ok

  defp do_spawn_knobs_reading(pins, knob_ids, knob_directions, number_of_knobs, destination_pid) do
    current_knob_index = number_of_knobs - 1
    knob_pin = elem(pins, current_knob_index)
    knob_id = elem(knob_ids, current_knob_index)
    knob_direction = elem(knob_directions, current_knob_index)

    spawn(fn ->
      read_knob_loop(knob_pin, destination_pid, current_knob_index, knob_id, knob_direction, nil)
    end)

    # Repeat until all knobs get a process
    do_spawn_knobs_reading(pins, knob_ids, knob_directions, number_of_knobs - 1, destination_pid)
  end

  # Continuous loop for reading knob values
  defp read_knob_loop(pin, destination_pid, knob_index, knob_id, direction, prev_midi_value) do
    case read_analog(pin, direction) do
      {:ok, {_raw_value, _voltage, midi_value} = knob_value} ->
        # Only send if the MIDI value has changed
        if midi_value != prev_midi_value do
          send(destination_pid, {:knob_value_with_index, knob_index, knob_id, knob_value})
        end

        # Sleep to reduce CPU load and prevent watchdog timeout
        # Longer sleep ensures IDLE task gets enough CPU time
        Process.sleep(150)
        read_knob_loop(pin, destination_pid, knob_index, knob_id, direction, midi_value)

      {:error, reason} ->
        IO.puts("[#{knob_id}] Error reading knob: #{inspect(reason)}")
        Process.sleep(150)
        read_knob_loop(pin, destination_pid, knob_index, knob_id, direction, prev_midi_value)
    end
  end

  @doc """
  Reading the value from an analog potentiometer.
  Parameters:
    - pin: ADC pin number
    - direction: :cw (clockwise/normal) or :ccw (counter-clockwise/inverted)
  """
  def read_analog(pin, direction \\ :cw) do
    case :esp_adc.read(pin) do
      {:ok, reading} ->
        {raw_value, voltage} = reading
        midi_value = map_to_midi_value(direction, raw_value)

        # Adding midi value mapping to the result
        {:ok, {raw_value, voltage, midi_value}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Mapping the raw value from potentiometer to 0-127 value.

  # Arguments:
  #   - direction: :cw (clockwise, normal) or :ccw (counter-clockwise, inverted)
  #   - raw_value is the first tuple element from esp_adc.read()
  #   - max_raw_value is the max value of potentiometer. 4095 is because I use B10K potentiometer.

  # Function head with default value
  defp map_to_midi_value(direction, raw_value, max_raw_value \\ 4095)

  # Clockwise (normal mapping): 0 -> 0, 4095 -> 127
  defp map_to_midi_value(:cw, raw_value, max_raw_value) do
    # 127 is maximum midi cc value
    div(raw_value * 127, max_raw_value)
  end

  # Counter-clockwise (inverted mapping): 0 -> 127, 4095 -> 0
  # This compensates for incorrectly wired potentiometers
  defp map_to_midi_value(:ccw, raw_value, max_raw_value) do
    # Invert the mapping
    127 - div(raw_value * 127, max_raw_value)
  end
end
