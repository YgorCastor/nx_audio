defmodule NxAudio.IO.Backends.FFmpegWriter do
  @moduledoc """
  Writing operations using the FFmpeg backend
  """
  @moduledoc section: :io
  use FFmpex.Options

  import FFmpex

  alias NxAudio.IO.Errors.{FailedToBufferFile, FailedToExecuteBackend}

  @doc false
  def save(uri, tensor, config) do
    channels_first = Keyword.get(config, :channels_first)
    sample_rate = Keyword.fetch!(config, :sample_rate)

    tensor = if channels_first, do: Nx.transpose(tensor), else: tensor
    {channels, _shape} = Nx.shape(tensor)

    with raw_audio <- tensor_to_raw_data(tensor),
         {:ok, tmp_file} <- buffer_to_temp_file(raw_audio, sample_rate, channels) do
      run_ffmpeg(tmp_file, uri, sample_rate, channels, config)
    end
  end

  defp tensor_to_raw_data(tensor) do
    tensor
    |> convert_tensor_for_save()
    |> Nx.to_binary()
  end

  defp convert_tensor_for_save(tensor) do
    if Nx.type(tensor) == {:f, 32} do
      tensor
      |> Nx.clip(-1.0, 1.0)
      |> Nx.multiply(32_767.0)
      |> Nx.round()
      |> Nx.as_type({:s, 16})
    else
      Nx.as_type(tensor, {:s, 16})
    end
  end

  defp buffer_to_temp_file(raw_data, sample_rate, channels) do
    with {:ok, tmp_file_path} <- Briefly.create(),
         :ok <- write_wav_file(tmp_file_path, raw_data, sample_rate, channels) do
      {:ok, tmp_file_path}
    else
      {:error, err} -> {:error, FailedToBufferFile.exception(reason: err)}
    end
  end

  defp write_wav_file(path, raw_data, sample_rate, channels) do
    bits_per_sample = 16
    byte_rate = div(sample_rate * channels * bits_per_sample, 8)
    block_align = div(channels * bits_per_sample, 8)
    data_size = byte_size(raw_data)
    # Total size - 8 bytes for RIFF header
    file_size = data_size + 36

    # RIFF header
    # Format chunk
    # Chunk size
    # Audio format (PCM)
    # Number of channels
    # Sample rate
    # Byte rate
    # Block align
    # Data chunk
    header =
      "RIFF" <>
        <<file_size::little-size(32)>> <>
        "WAVE" <>
        "fmt " <>
        <<16::little-size(32)>> <>
        <<1::little-size(16)>> <>
        <<channels::little-size(16)>> <>
        <<sample_rate::little-size(32)>> <>
        <<byte_rate::little-size(32)>> <>
        <<block_align::little-size(16)>> <>
        <<bits_per_sample::little-size(16)>> <>
        "data" <>
        <<data_size::little-size(32)>>

    File.write(path, header <> raw_data)
  end

  defp run_ffmpeg(input_file, output_file, sample_rate, channels, opts) do
    result =
      FFmpex.new_command()
      |> add_global_option(option_y())
      |> add_input_file(input_file)
      |> add_output_file(output_file)
      |> add_stream_specifier(stream_type: :audio)
      |> maybe_overwrite_encoding(opts[:encoding])
      |> add_stream_option(option_ar(sample_rate))
      |> add_stream_option(option_ac(channels))
      |> execute()

    case result do
      {:ok, ""} ->
        :ok

      {:error, error} ->
        {:error, FailedToExecuteBackend.exception(backend: :ffmpeg, reason: error)}
    end
  end

  defp maybe_overwrite_encoding(command, nil), do: command

  defp maybe_overwrite_encoding(command, encoding),
    do:
      command
      |> add_stream_option(
        encoding
        |> encoding_to_codec()
        |> option_acodec()
      )

  defp encoding_to_codec(encoding) do
    case encoding do
      Type.PCM_U8 -> "pcm_u8"
      Type.PCM_S16LE -> "pcm_s16le"
      Type.PCM_S24LE -> "pcm_s24le"
      Type.PCM_S32LE -> "pcm_s32le"
      _ -> "pcm_s16le"
    end
  end
end
