defmodule Knob do
  @moduledoc """
  Knob is a module to abstract the reading of knob component attached to the microcontroller.
  It can be an analog potentiometer or rotary encoder.

  Currently it only supports analog potentiometer.
  """

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
