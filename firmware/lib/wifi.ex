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
defmodule MidimeshEsp32.WiFi do
  @moduledoc """
  Various functions related to WiFi networking.
  """

  @doc """
  Get the configuration for the device networking mode.
  """
  def get_config(mode, opts \\ [])

  def get_config(:sta_mode, opts) do
    {:ok,
     [
       sta: [
         # SSID name
         ssid: MidimeshEsp32.Config.ssid_name(),
         # SSID password
         psk: MidimeshEsp32.Config.ssid_password(),
         connected: Keyword.get(opts, :connected, &connected/0),
         got_ip: Keyword.get(opts, :got_ip, &got_ip/1),
         disconnected: Keyword.get(opts, :disconnected, &disconnected/0),
         dhcp_hostname: "midimesh_esp32"
       ]
     ]}
  end

  def get_config(:ap_mode, opts) do
    {:ok,
     [
       ap: [
         ssid: "midiMESH-SlideAndTwist",
         ap_started: Keyword.get(opts, :ap_started, &ap_started/0),
         sta_connected: Keyword.get(opts, :sta_connected, &sta_connected/1),
         sta_ip_assigned: Keyword.get(opts, :sta_ip_assigned, &sta_ip_assigned/1),
         sta_disconnected: Keyword.get(opts, :sta_disconnected, &sta_disconnected/1)
       ]
     ]}
  end

  def get_config(_, _opts) do
    {:error, "No configuration for this mode"}
  end

  defp connected do
    IO.puts("Connected to WiFi!")
  end

  defp got_ip(ip_info) do
    IO.puts("Got IP: #{inspect(ip_info)}")
  end

  defp disconnected do
    IO.puts("Disconnected from WiFi")
  end

  defp ap_started do
  end

  defp sta_connected(_) do
  end

  defp sta_ip_assigned(_) do
  end

  defp sta_disconnected(_) do
  end
end
