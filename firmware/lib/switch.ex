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
  A gen_statem-based switch monitor for ESP32 GPIO pins.

  Continuously monitors GPIO switch state and restarts the device if the
  switch position changes from its boot state.

  ## State Diagram

  ```
       [BOOT]
         ↓
     Read GPIO
         ↓
    Initial State
         ↓
  ┌──────────────┐          GPIO changes          ┌────────────────┐
  │ switch_open  │ ──────────────────────────────→│ switch_closed  │
  │              │                                │                │
  │ (GPIO :high) │ ←──────────────────────────────│ (GPIO :low)    │
  └──────────────┘          GPIO changes          └────────────────┘
         ↓                                                  ↓
    Poll every 150ms                                  Poll every 150ms
         ↓                                                  ↓
    Check if changed                                  Check if changed
    from boot state                                   from boot state
         ↓                                                  ↓
    If YES → :esp.restart()                          If YES → :esp.restart()
  ```

  ## Usage

  ```elixir
  # Start the switch monitor
  {:ok, pid} = MidimeshEsp32.Switch.start_link(pin: 10)

  # Get current state
  {:ok, state} = MidimeshEsp32.Switch.get_state(pid)

  # Get boot state
  {:ok, boot_state} = MidimeshEsp32.Switch.get_boot_state(pid)
  ```
  """

  @behaviour :gen_statem
  @compile {:no_warn_undefined, [GPIO]}

  # Public API

  @doc """
  Starts the switch state machine as a linked process.
  """
  def start_link(opts) when is_list(opts) do
    :gen_statem.start_link(__MODULE__, opts, [])
  end

  @doc """
  Gets the current state of the switch.
  Returns `{:ok, :switch_open}` or `{:ok, :switch_closed}`.
  """
  def get_state(server) do
    :gen_statem.call(server, :get_state)
  end

  @doc """
  Gets the boot state (initial state when device started).
  """
  def get_boot_state(server) do
    :gen_statem.call(server, :get_boot_state)
  end

  @doc """
  Stops the switch state machine gracefully.
  """
  def stop(server) do
    :gen_statem.stop(server)
  end

  # gen_statem callbacks

  @doc false
  @impl :gen_statem
  def callback_mode do
    # Use :state_functions mode - each state has its own function
    :state_functions
  end

  @doc false
  @impl :gen_statem
  def init(opts) do
    pin = Keyword.fetch!(opts, :pin)

    IO.puts("\n=== Switch State Machine Initializing ===")
    IO.puts("GPIO Pin: #{pin}")

    # Initialize GPIO with pull-up resistor
    GPIO.set_pin_mode(pin, :input)
    GPIO.set_pin_pull(pin, :up)

    # Read boot state
    gpio_level = GPIO.digital_read(pin)
    boot_state = gpio_to_state(gpio_level)

    IO.puts("Initial GPIO reading: #{gpio_level}")
    IO.puts("Boot state: #{boot_state}")
    IO.puts("Monitoring will begin - device will restart if switch changes from boot position")

    data = %{
      pin: pin,
      boot_state: boot_state
    }

    # Start in boot_state, schedule first poll after 150ms
    {:ok, boot_state, data, [{:state_timeout, 150, :poll}]}
  end

  # State functions

  @doc false
  def switch_open(event_type, event_content, data)

  # Poll GPIO state every 150ms
  def switch_open(:state_timeout, :poll, data) do
    current_gpio = GPIO.digital_read(data.pin)

    case current_gpio do
      :high ->
        # Stay in switch_open state, schedule next poll
        {:next_state, :switch_open, data, [{:state_timeout, 150, :poll}]}

      :low ->
        IO.puts("[switch_open] State change detected: GPIO changed from :high to :low")
        check_state_change(:switch_closed, data)
    end
  end

  # Handle API calls
  def switch_open({:call, from}, :get_state, data) do
    {:next_state, :switch_open, data, [{:reply, from, {:ok, :switch_open}}]}
  end

  def switch_open({:call, from}, :get_boot_state, data) do
    {:next_state, :switch_open, data, [{:reply, from, {:ok, data.boot_state}}]}
  end

  @doc false
  def switch_closed(event_type, event_content, data)

  # Poll GPIO state every 150ms
  def switch_closed(:state_timeout, :poll, data) do
    current_gpio = GPIO.digital_read(data.pin)

    case current_gpio do
      :low ->
        # Stay in switch_closed state, schedule next poll
        {:next_state, :switch_closed, data, [{:state_timeout, 150, :poll}]}

      :high ->
        IO.puts("[switch_closed] State change detected: GPIO changed from :low to :high")
        check_state_change(:switch_open, data)
    end
  end

  # Handle API calls
  def switch_closed({:call, from}, :get_state, data) do
    {:next_state, :switch_closed, data, [{:reply, from, {:ok, :switch_closed}}]}
  end

  def switch_closed({:call, from}, :get_boot_state, data) do
    {:next_state, :switch_closed, data, [{:reply, from, {:ok, data.boot_state}}]}
  end

  # Private helpers

  defp gpio_to_state(:high), do: :switch_open
  defp gpio_to_state(:low), do: :switch_closed

  defp check_state_change(new_state, data) do
    if new_state != data.boot_state do
      Process.sleep(1000)
      :esp.restart()
    else
      # Switch returned to boot state - continue monitoring
      IO.puts("[check_state_change] Switch returned to boot state (#{data.boot_state})")
      {:next_state, new_state, data, [{:state_timeout, 150, :poll}]}
    end
  end
end
