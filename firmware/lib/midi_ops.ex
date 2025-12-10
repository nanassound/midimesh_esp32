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
