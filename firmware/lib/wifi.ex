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

  def get_config(:sta_mode, _opts) do
    {:ok,
     [
       # SSID name
       ssid: MidimeshEsp32.Config.ssid_name(),
       # SSID password
       psk: MidimeshEsp32.Config.ssid_password()
     ]}
  end

  def get_config(:ap_mode, _opts) do
    {:ok,
     [
       ssid: "midiMESH-SlideAndTwist"
     ]}
  end

  def get_config(_, _opts) do
    {:error, "No configuration for this mode"}
  end

  @doc """
  Start and wait for the specific network mode.
  Valid option is :sta_mode (station) and :ap_mode (access point).
  """
  def wait_for_mode(:sta_mode, sta_config, callback_fn) do
    case :network.wait_for_sta(sta_config, 15000) do
      {:ok, ip_info} ->
        IO.puts("midiMESH STA mode got IP: #{inspect(ip_info)}")

        # Send the ip info to the callback function
        callback_fn.(ip_info)

        {:ok, ip_info}

      {:error, reason} ->
        IO.puts("Failed to start network: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def wait_for_mode(:ap_mode, ap_config, callback_fn) do
    case :network.wait_for_ap(ap_config, 15000) do
      :ok ->
        callback_fn.()
        :ok

      {:error, reason} ->
        IO.puts("Failed to start network: #{inspect(reason)}")
        {:error, reason}
    end
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
    IO.puts("ORIGINAL AP STARTED")
  end

  defp sta_connected(_) do
  end

  defp sta_ip_assigned(_) do
  end

  defp sta_disconnected(_) do
  end
end
