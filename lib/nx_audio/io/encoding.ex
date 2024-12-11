defmodule NxAudio.IO.Encoding do
  @moduledoc """
  Represents the supported audio encodings
  """
  @moduledoc section: :io
  use EnumType

  defenum Type do
    value PCM_S16, "PCM_S16" do
      def codec_names(), do: ["pcm_s16le"]
    end

    value PCM_S24, "PCM_S24" do
      def codec_names(), do: ["pcm_s24le"]
    end

    value PCM_S32, "PCM_S32" do
      def codec_names(), do: ["pcm_s32le"]
    end

    value PCM_S8, "PCM_S8" do
      def codec_names(), do: ["pcm_s8"]
    end

    value PCM_U8, "PCM_U8" do
      def codec_names(), do: ["pcm_u8"]
    end

    value PCM_F32, "PCM_F32" do
      def codec_names(), do: ["pcm_f32le"]
    end

    value PCM_F64, "PCM_F64" do
      def codec_names(), do: ["pcm_f64le"]
    end

    value FLAC, "FLAC" do
      def codec_names(), do: ["flac"]
    end

    value ULAW, "ULAW" do
      def codec_names(), do: ["pcm_mulaw"]
    end

    value ALAW, "ALAW" do
      def codec_names(), do: ["pcm_alaw"]
    end

    value MP3, "MP3" do
      def codec_names(), do: ["mp3"]
    end

    value VORBIS, "VORBIS" do
      def codec_names(), do: ["libvorbis", "vorbis"]
    end

    value OPUS, "OPUS" do
      def codec_names(), do: ["opus"]
    end

    value AMR_NB, "AMR_NB" do
      def codec_names(), do: ["amr_nb"]
    end

    value AMR_WB, "AMR_WB" do
      def codec_names(), do: ["amr_wb"]
    end

    value HTK, "HTK" do
      def codec_names(), do: ["htk"]
    end

    value(UNKNOWN, "UNKNOWN") do
      def codec_names(), do: []
    end

    default(UNKNOWN)
  end

  @doc """
  Checks if the encoding is PCM
  """
  defguard is_pcm?(encoding)
           when encoding in [
                  Type.PCM_S8,
                  Type.PCM_S16,
                  Type.PCM_S24,
                  Type.PCM_S32,
                  Type.PCM_U8,
                  Type.PCM_F32,
                  Type.PCM_F64
                ]

  @doc """
  Converts a codec name to an encoding
  """
  @spec codec_name_to_encoding(String.t()) :: Type.t()
  def codec_name_to_encoding(codec_name) do
    case Enum.find(Type.enums(), fn encoding ->
           Enum.any?(encoding.codec_names(), &(&1 == codec_name))
         end) do
      nil -> Type.UNKNOWN
      encoding -> encoding
    end
  end
end
