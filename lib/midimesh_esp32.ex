defmodule MidimeshEsp32 do
  @compile {:no_warn_undefined, [GPIO]}
  @led_pin 8 # built-in LED
  @knob_pin 0 # potentiometer

  # UDP Configuration
  @udp_target_ip {255, 255, 255, 255}  # Broadcast it!
  @udp_target_port 4000

  # MIDI Configuration
  @midi_channel 0  # Channel 1 (0-indexed)

  def start() do
    GPIO.set_pin_mode(@led_pin, :output)
    :esp_adc.start(@knob_pin)

    config = [
      sta: [
        ssid: MMConfig.ssid_name(), # SSID name
        psk: MMConfig.ssid_password(), # SSID password
        connected: &connected/0,
        got_ip: &got_ip/1,
        disconnected: &disconnected/0,
        dhcp_hostname: "midimesh_esp32"
      ]
    ]

    case :network.start(config) do
      {:ok, pid} ->
        IO.puts("Network started with pid: #{inspect(pid)}")
      {:error, reason} ->
        IO.puts("Failed to start network: #{inspect(reason)}")
        {:error, reason}
    end

    # Loop the main process forever
    wait_forever()
  end

  defp connected do
    IO.puts("Connected to WiFi!")
  end

  # Since this MIDI controller works exclusively via WiFi
  # Then we will do everything after this device get IP address
  defp got_ip(ip_info) do
    IO.puts("Got IP: #{inspect(ip_info)}")

    # Start LED blinking in a separate process.
    # It acts as an indicator that this device successfully connected to the WiFi
    # and get an IP address
    spawn(fn -> blinking_led(@led_pin, :low) end)

    # Start udp sender process
    spawn(fn -> start_udp_sender() end)
  end

  defp disconnected do
    IO.puts("Disconnected from WiFi")
  end

  defp blinking_led(pin, level) do
    GPIO.digital_write(pin, level)
    Process.sleep(1000)
    blinking_led(pin, toggle(level))
  end

  defp toggle(:high), do: :low
  defp toggle(:low), do: :high

  defp read_knob(pin, socket, prev_cc_val) do
    knob_val = Knob.read_analog(pin)
    current_cc_val = case knob_val do
      {:ok, {_, _, cc_val}} ->
        # Only send if value changed
        if cc_val != prev_cc_val do
          # hardcoded CC number
          # TODO: need to think how to make it configurable
          cc_number = 16
          status_byte = 0xB0 + @midi_channel
          cc_data = <<status_byte, cc_number, cc_val>>
          MidiOps.send_midi(socket, cc_data, @udp_target_ip, @udp_target_port)
        end
        cc_val

      {:error, reason} ->
        IO.puts("Error knob 1: #{inspect(reason)}")
        prev_cc_val
    end

    Process.sleep(15)
    read_knob(pin, socket, current_cc_val)
  end

  defp wait_forever do
    Process.sleep(10000)
    wait_forever()
  end

  # UDP Sender Functions
  defp start_udp_sender do
    IO.puts("Starting UDP sender...")
    case :gen_udp.open(0) do
      {:ok, socket} ->
        IO.puts("UDP socket opened successfully")

        # Reading the knob in a separate process
        spawn(fn -> read_knob(@knob_pin, socket, nil) end)

      {:error, reason} ->
        IO.puts("Failed to open UDP socket: #{inspect(reason)}")
    end
  end
end
