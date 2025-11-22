defmodule MidimeshEsp32 do
  @compile {:no_warn_undefined, [GPIO]}
  @pin 8

  # UDP Configuration
  @udp_target_ip {255, 255, 255, 255}  # Broadcast it!
  @udp_target_port 4000

  # MIDI Configuration
  @midi_channel 0  # Channel 1 (0-indexed)
  @note_on 0x90    # Note On status byte
  @note_off 0x80   # Note Off status byte
  @min_note 48     # C3
  @max_note 71     # B4
  @note_duration 500   # How long to hold note (ms)
  @note_interval 1000  # Time between notes (ms)

  def start() do
    GPIO.set_pin_mode(@pin, :output)

    config = [
      sta: [
        ssid: "", # SSID name
        psk: "", # SSID password
        connected: &connected/0,
        got_ip: &got_ip/1,
        disconnected: &disconnected/0,
        dhcp_hostname: "midimesh_esp32"
      ]
    ]

    case :network.start(config) do
      {:ok, pid} ->
        IO.puts("Network started with pid: #{inspect(pid)}")

        # Keep the main process alive
        wait_forever()
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

    # Start LED blinking in a separate process
    spawn(fn -> blinking_led(@pin, :low) end)

    # Start UDP sender in a separate process
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
        udp_send_loop(socket, 0)
      {:error, reason} ->
        IO.puts("Failed to open UDP socket: #{inspect(reason)}")
    end
  end

  defp udp_send_loop(socket, counter) do
    # Generate a pseudo-random note based on counter
    note = get_note(counter)
    velocity = get_velocity(counter)

    # Send Note On
    note_on_msg = create_note_on(note, velocity)
    send_midi(socket, note_on_msg)
    IO.puts("Note On: #{note} vel: #{velocity}")

    # Hold the note
    Process.sleep(@note_duration)

    # Send Note Off
    note_off_msg = create_note_off(note)
    send_midi(socket, note_off_msg)
    IO.puts("Note Off: #{note}")

    # Wait before next note
    Process.sleep(@note_interval)
    udp_send_loop(socket, counter + 1)
  end

  defp send_midi(socket, data) do
    case :gen_udp.send(socket, @udp_target_ip, @udp_target_port, data) do
      :ok -> :ok
      {:error, reason} ->
        IO.puts("Failed to send MIDI: #{inspect(reason)}")
    end
  end

  # MIDI Message Generators
  defp create_note_on(note, velocity) do
    status = @note_on + @midi_channel
    <<status, note, velocity>>
  end

  defp create_note_off(note) do
    status = @note_off + @midi_channel
    <<status, note, 0>>
  end

  # Pseudo-random note selection (since :rand unavailable)
  defp get_note(counter) do
    range = @max_note - @min_note + 1
    @min_note + rem(counter * 7, range)
  end

  # Pseudo-random velocity (64-127)
  defp get_velocity(counter) do
    64 + rem(counter * 13, 64)
  end
end
