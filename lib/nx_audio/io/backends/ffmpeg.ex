defmodule NxAudio.IO.Backends.FFmpeg do
  @moduledoc """
  Implements a FFMPEG backend to deal with audio files.
  This module requires FFMPEG to be installed on the system.
  """
  @moduledoc section: :io
  use FFmpex.Options

  import NxAudio.IO.Encoding

  alias NxAudio.IO.AudioMetadata
  alias NxAudio.IO.Errors.InvalidMetadata

  @behaviour NxAudio.IO

  @impl true
  defdelegate load(uri, opts), to: NxAudio.IO.Backends.FFmpegReader

  @impl true
  defdelegate save(uri, tensor, config), to: NxAudio.IO.Backends.FFmpegWriter

  @impl true
  def info(uri) do
    uri
    |> FFprobe.streams()
    |> parse_ffprobe_result()
  end

  defp parse_ffprobe_result({:ok, result}) do
    result
    |> List.first()
    |> then(fn probe ->
      {:ok,
       %AudioMetadata{
         sample_rate: probe["sample_rate"] |> String.to_integer(),
         num_frames: probe["duration_ts"],
         num_channels: probe["channels"],
         bits_per_sample: probe["bits_per_sample"],
         encoding: probe["codec_name"] |> codec_name_to_encoding()
       }}
    end)
  end

  defp parse_ffprobe_result({:error, err}) do
    {:error, InvalidMetadata.exception(reason: err)}
  end
end
