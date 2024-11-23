defmodule NxAudio.IO.Backends.FFmpegReader do
  @moduledoc """
  Reading operations using the FFmpeg backend
  """
  @moduledoc section: :io
  use FFmpex.Options

  import FFmpex
  import NxAudio.IO.Encoding

  alias NxAudio.IO.Errors.FailedToExecuteBackend

  @doc false
  def load(uri, opts) do
    with {:ok, audio_metadata} <- NxAudio.IO.Backends.FFmpeg.info(uri),
         {:ok, raw_data} <-
           encode_audio(
             uri,
             audio_metadata,
             opts
           ),
         tensor <- to_tensor(raw_data, audio_metadata, opts) do
      {:ok, {tensor, audio_metadata.sample_rate}}
    end
  end

  defp encode_audio(uri, audio_metadata, opts) do
    codec = get_output_codec(audio_metadata.bits_per_sample)

    result =
      FFmpex.new_command()
      |> add_global_option(option_y())
      |> add_input_file(uri)
      |> to_stdout()
      |> add_stream_specifier(stream_type: :audio)
      |> maybe_add_frame_offset(opts[:frame_offset], audio_metadata)
      |> maybe_add_num_frames(opts[:num_frames], audio_metadata)
      |> add_stream_option(option_acodec(codec))
      |> add_stream_option(option_ar(audio_metadata.sample_rate))
      |> add_stream_option(option_ac(audio_metadata.num_channels))
      |> add_file_option(option_f("wav"))
      |> execute()

    case result do
      {:ok, raw_data} ->
        {:ok, raw_data}

      {:error, error} ->
        {:error, FailedToExecuteBackend.exception(backend: :ffmpeg, reason: error)}
    end
  end

  defp maybe_add_frame_offset(command, frame_offset, metadata) do
    if frame_offset > 0 do
      time_offset = frame_offset / metadata.sample_rate
      add_stream_option(command, option_ss(time_offset))
    else
      command
    end
  end

  defp maybe_add_num_frames(command, num_frames, metadata) do
    if num_frames > 0 do
      duration = num_frames / metadata.sample_rate
      add_stream_option(command, option_t(duration))
    else
      command
    end
  end

  defp get_output_codec(bits) do
    case bits do
      8 -> "pcm_u8"
      16 -> "pcm_s16le"
      24 -> "pcm_s24le"
      32 -> "pcm_s32le"
      # Default to 16-bit
      _ -> "pcm_s16le"
    end
  end

  defp to_tensor(raw_data, %{encoding: encoding, num_channels: num_channels}, opts) do
    original_type = get_type(encoding)

    # Calculate samples based on original type before normalization
    bytes_per_sample = bytes_per_sample(original_type)
    samples = div(byte_size(raw_data), bytes_per_sample)
    frames = div(samples, num_channels)

    tensor =
      raw_data
      |> Nx.from_binary(original_type)
      |> Nx.reshape({frames, num_channels})

    tensor =
      if opts[:normalize] && is_pcm?(encoding) do
        max_value = get_max_value(original_type)
        Nx.divide(Nx.as_type(tensor, {:f, 32}), max_value)
      else
        tensor
      end

    if opts[:channels_first], do: Nx.transpose(tensor), else: tensor
  end

  defp get_max_value({:s, 8}), do: 128
  defp get_max_value({:s, 16}), do: 32_768
  defp get_max_value({:s, 32}), do: 2_147_483_648
  defp get_max_value({:u, 8}), do: 255

  defp get_type(NxAudio.IO.Encoding.Type.PCM_U8), do: {:u, 8}
  defp get_type(NxAudio.IO.Encoding.Type.PCM_S8), do: {:s, 8}
  defp get_type(NxAudio.IO.Encoding.Type.PCM_S16), do: {:s, 16}
  defp get_type(NxAudio.IO.Encoding.Type.PCM_S24), do: {:s, 32}
  defp get_type(NxAudio.IO.Encoding.Type.PCM_S32), do: {:s, 32}
  defp get_type(_), do: {:f, 32}

  defp bytes_per_sample({_, 8}), do: 1
  defp bytes_per_sample({_, 16}), do: 2
  defp bytes_per_sample({_, 32}), do: 4
end
