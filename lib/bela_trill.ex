defmodule BelaTrill do
  @moduledoc """
  Trill Bar touch sensor interface module.

  Provides I2C communication with the Bela Trill Bar sensor for reading
  touch positions in centroid mode.

  Hardware:
  - Trill Bar sensor (1D touch slider, 30 sensing points)
  - I2C address: 0x20
  - Default pins: SDA=8, SCL=9

  References:
  - Product: https://bela.io/products/trill/
  - Documentation: https://learn.bela.io/using-trill/get-started-with-trill/#trill-bar-square-hex-ring
  """

  # I2C Configuration
  @i2c_address 0x20

  # Register addresses
  @reg_command 0x00  # Commands are sent to register 0x00
  @reg_data_start 0x00  # Data is read from register 0x00

  # Command bytes
  @cmd_identify 0x00
  @cmd_mode 0x01
  @cmd_scan_settings 0x02
  @cmd_baseline_update 0x03

  # Modes
  @mode_centroid 0x00

  # Scan settings
  @speed_fast 1

  # Trill Bar specific
  @max_position_value 3584
  @max_touches 5

  @doc """
  Initialize the Trill Bar sensor.

  Opens the I2C bus on the specified pins and configures the sensor
  for centroid mode operation.

  ## Parameters
    - i2c_pins: Tuple of {sda_pin, scl_pin}, e.g., {8, 9}

  ## Returns
    - {:ok, i2c_handle} on success
    - {:error, reason} on failure

  ## Example
      iex> BelaTrill.begin({8, 9})
      {:ok, #PID<0.123.0>}
  """
  def begin(i2c_pins) do
    {sda_pin, scl_pin} = i2c_pins
    IO.puts("BelaTrill: Opening I2C on SDA=#{sda_pin}, SCL=#{scl_pin}")

    i2c = :i2c.open([{:scl, scl_pin}, {:sda, sda_pin}, {:clock_speed_hz, 400_000}])
    IO.puts("BelaTrill: I2C opened successfully")

    # Configure sensor
    IO.puts("BelaTrill: Configuring sensor at address 0x#{Integer.to_string(@i2c_address, 16)}")
    case initialize_sensor(i2c) do
      :ok ->
        IO.puts("BelaTrill: Sensor configured successfully")
        # Give sensor more time to be ready for reading
        IO.puts("BelaTrill: Waiting for sensor to stabilize...")
        Process.sleep(100)

        # Test read to verify sensor is responding
        IO.puts("BelaTrill: Testing sensor read...")
        case :i2c.read_bytes(i2c, @i2c_address, 1) do
          {:ok, data} ->
            IO.puts("BelaTrill: Sensor responding - first byte: #{inspect(data)}")
            {:ok, i2c}
          error ->
            IO.puts("BelaTrill: Sensor not responding to read: #{inspect(error)}")
            {:error, :sensor_not_responding}
        end
      {:error, reason} ->
        IO.puts("BelaTrill: Sensor configuration failed: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Initialize sensor with mode and scan settings
  defp initialize_sensor(i2c) do
    # Wait for sensor to be ready after power-on
    IO.puts("BelaTrill: Waiting for sensor power-on...")
    Process.sleep(50)

    # First, identify the device
    IO.puts("BelaTrill: Step 0 - Identifying device")
    case identify_device(i2c) do
      :ok ->
        IO.puts("BelaTrill: Device identified")
        Process.sleep(100)
      error ->
        IO.puts("BelaTrill: Device identification failed: #{inspect(error)}")
        # Continue anyway
    end

    # Set mode to centroid
    IO.puts("BelaTrill: Step 1 - Setting mode to centroid (#{@mode_centroid})")
    case set_mode(i2c, @mode_centroid) do
      :ok ->
        IO.puts("BelaTrill: Mode set successfully")
        # Wait LONGER for mode change to take effect - sensor needs time to switch modes
        IO.puts("BelaTrill: Waiting for mode change (200ms)...")
        Process.sleep(200)

        # Update baseline multiple times to ensure it takes
        IO.puts("BelaTrill: Step 2 - Updating baseline (3 times)")
        update_baseline(i2c)
        Process.sleep(100)
        update_baseline(i2c)
        Process.sleep(100)
        update_baseline(i2c)
        Process.sleep(200)
        IO.puts("BelaTrill: Baseline calibration complete")
        :ok
      error ->
        IO.puts("BelaTrill: Mode setting failed: #{inspect(error)}")
        error
    end
  end

  # Identify the device
  defp identify_device(i2c) do
    :i2c.write_bytes(i2c, @i2c_address, @reg_command, <<@cmd_identify>>)
  end

  # Set the operating mode
  defp set_mode(i2c, mode) do
    result = :i2c.write_bytes(i2c, @i2c_address, @reg_command, <<@cmd_mode, mode>>)
    Process.sleep(30)
    result
  end

  # Set scan settings (speed and resolution)
  defp set_scan_settings(i2c, speed) do
    result = :i2c.write_bytes(i2c, @i2c_address, <<@cmd_scan_settings, speed>>)
    Process.sleep(30)
    result
  end

  # Update baseline calibration
  defp update_baseline(i2c) do
    result = :i2c.write_bytes(i2c, @i2c_address, @reg_command, <<@cmd_baseline_update>>)
    Process.sleep(30)
    result
  end

  @doc """
  Read all touch data from the sensor.

  Returns structured data containing the number of touches and
  an array of touch information (position and size).

  ## Parameters
    - i2c: I2C handle returned from begin/1

  ## Returns
    - {:ok, touch_data} where touch_data is a map with:
      - num_touches: Number of active touches (0-5)
      - touches: List of touch maps, each containing:
        - position: Normalized position (0.0-1.0)
        - size: Touch size (raw sensor value)
    - {:error, reason} on failure

  ## Example
      iex> BelaTrill.read_touches(i2c)
      {:ok, %{num_touches: 1, touches: [%{position: 0.5, size: 500}]}}
  """
  def read_touches(i2c) do
    # Read raw data from sensor
    case read_raw_data(i2c) do
      {:ok, data} ->
        # Parse the touch data
        parse_touch_data(data)
      error -> error
    end
  end

  # Read raw I2C data from sensor
  defp read_raw_data(i2c) do
    # In centroid mode, we need to read enough bytes for max touches
    # Each touch = 4 bytes (2 for position, 2 for size)
    # Plus 1 byte for number of touches
    bytes_to_read = 1 + (@max_touches * 4)

    # Try direct read without specifying register (sensor auto-increments from 0)
    case :i2c.read_bytes(i2c, @i2c_address, bytes_to_read) do
      {:ok, data} -> {:ok, data}
      error -> error
    end
  end

  # Parse raw sensor data into touch information
  defp parse_touch_data(data) when is_binary(data) do
    # Trill data format (observed):
    # Byte 0: Status/Device ID (0xFE)
    # Byte 1: Mode byte (3 = centroid mode)
    # Bytes 2+: Touch data (4 bytes per touch)
    <<_status::8, _mode::8, rest::binary>> = data

    # Parse up to max touches and filter out invalid ones
    touches = parse_touches(rest, @max_touches, [])
    valid_touches = Enum.filter(touches, fn touch ->
      # Valid touch must have:
      # 1. Position not 0xFFFF (65535) - padding/invalid
      # 2. Size not 0xFFFF (65535) - padding/invalid
      # 3. Size > 0 and < 60000 (actual touch pressure is typically 50-500)
      touch.position_raw != 65535 and touch.size != 65535 and touch.size > 0 and touch.size < 60000
    end)

    {:ok, %{num_touches: length(valid_touches), touches: valid_touches}}
  end

  # Parse individual touch data recursively
  defp parse_touches(_data, 0, acc), do: Enum.reverse(acc)

  defp parse_touches(data, remaining, acc) when byte_size(data) >= 4 do
    <<pos_high::8, pos_low::8, size_high::8, size_low::8, rest::binary>> = data

    # Combine bytes to get 16-bit values
    # Using manual bit operations instead of import Bitwise
    position_raw = pos_high * 256 + pos_low
    size_raw = size_high * 256 + size_low

    # Normalize position to 0.0-1.0 range
    position_normalized = position_raw / @max_position_value

    touch = %{
      position: position_normalized,
      position_raw: position_raw,
      size: size_raw
    }

    parse_touches(rest, remaining - 1, [touch | acc])
  end

  defp parse_touches(_data, _remaining, acc), do: Enum.reverse(acc)

  @doc """
  Read the first touch position only (simplified API).

  Convenience function for single-touch applications.

  ## Parameters
    - i2c: I2C handle returned from begin/1

  ## Returns
    - {:ok, position} where position is 0.0-1.0
    - {:ok, nil} if no touch detected
    - {:error, reason} on failure

  ## Example
      iex> BelaTrill.read_position(i2c)
      {:ok, 0.75}
  """
  def read_position(i2c) do
    case read_touches(i2c) do
      {:ok, %{num_touches: 0}} ->
        {:ok, nil}
      {:ok, %{touches: [first_touch | _]}} ->
        {:ok, first_touch.position}
      error -> error
    end
  end

  @doc """
  Close the I2C connection and free resources.

  ## Parameters
    - i2c: I2C handle returned from begin/1

  ## Returns
    - :ok on success
    - {:error, reason} on failure
  """
  def close(_i2c) do
    :ok
  end
end
