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
  Activate multiple knobs based on the configuration.
  """
  def activate_knobs(_pins, 0), do: :ok

  def activate_knobs(pins, number_of_knobs) when number_of_knobs > 0 do
    current_knob_index = number_of_knobs - 1
    knob_pin = elem(pins, current_knob_index)

    # Initialize the knob pin
    :esp_adc.start(knob_pin)

    # Loop for the next knob
    activate_knobs(pins, current_knob_index)
  end

  @doc """
  Reading the value from an analog potentiometer.
  """
  def read_analog(pin) do
    case :esp_adc.read(pin) do
      {:ok, reading} ->
        {raw_value, voltage} = reading
        midi_value = map_to_midi_value(raw_value)

        # Adding midi value mapping to the result
        {:ok, {raw_value, voltage, midi_value}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Mapping the raw value from potentiometer to 0-127 value.

  # Arguments:
  #   - raw_value is the first tuple element fro esp_adc.read()
  #   - max_raw_value is the max value of potentiometer. 4095 is because I use B10K potentiometer.
  defp map_to_midi_value(raw_value, max_raw_value \\ 4095) do
    # 127 is maximum midi cc value
    div(raw_value * 127, max_raw_value)
  end
end
