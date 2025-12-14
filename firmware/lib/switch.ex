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
defmodule MidimeshEsp32.Switch do
  @moduledoc """
  This file handle any operations related to the switch component.
  """

  @doc """
  Activate multiple switches based on the configuration.
  This function supports SPDT or SPST switch.
  """
  def activate_switches(_pin, 0), do: :ok

  def activate_switches(pins, number_of_pins) when number_of_pins > 0 do
    current_switch_index = number_of_pins - 1
    switch_pin = elem(pins, current_switch_index)

    # Initialize the switch pin
    GPIO.set_pin_mode(switch_pin, :input)

    # Add internal pull-up resistor - pin reads HIGH when switch is open
    # Reads LOW when switch connects to GND
    GPIO.set_pin_pull(switch_pin, :up)

    # Loop for the next knob
    activate_switches(pins, current_switch_index)
  end

  def read_state(pin) do
    state = GPIO.digital_read(pin)
    IO.puts("Switch state on pin #{pin}: #{inspect(state)}")
    state
  end
end
