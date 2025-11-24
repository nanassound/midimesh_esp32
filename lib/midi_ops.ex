defmodule MidiOps do
  @moduledoc """
  Various functions related to MIDI.
  """

  @doc """
  Send MIDI data over UDP.
  """
  def send_midi(socket, data, udp_target_ip, udp_target_port) do
    case :gen_udp.send(socket, udp_target_ip, udp_target_port, data) do
      :ok -> :ok
      {:error, reason} ->
        IO.puts("Failed to send MIDI: #{inspect(reason)}")
    end
  end
end
