defmodule NxAudio.IO.Backends.FFmpegTest do
  use ExUnit.Case, async: true

  alias NxAudio.IO.AudioMetadata
  alias NxAudio.IO.Backends.FFmpeg
  alias NxAudio.IO.{BackendReadConfig, BackendSaveConfig}

  describe "load/2" do
    test "successfully loads an pcm_s16le encoded wav file" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"

      {:ok, backend_config} = BackendReadConfig.validate([])
      {:ok, {tensor, sample_rate}} = FFmpeg.load(uri, backend_config)

      assert sample_rate == 44_100

      assert Nx.shape(tensor) == {2, 262_117}
      assert Nx.type(tensor) == {:f, 32}
    end

    test "should be able to deal with a different file format" do
      uri = "test/fixtures/audio_samples/compressed.ogg"

      {:ok, backend_config} = BackendReadConfig.validate([])
      {:ok, {tensor, sample_rate}} = FFmpeg.load(uri, backend_config)

      assert sample_rate == 22_050

      assert Nx.shape(tensor) == {1, 65_543}
      assert Nx.type(tensor) == {:f, 32}
    end

    test "handles frame offset correctly" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"
      frame_offset = 22_050

      {:ok, backend_config} = BackendReadConfig.validate(frame_offset: frame_offset)
      {:ok, {tensor, _}} = FFmpeg.load(uri, backend_config)

      assert Nx.shape(tensor) == {2, 240_067}
    end

    test "respects num_frames parameter" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"

      {:ok, backend_config} = BackendReadConfig.validate(num_frames: 11_025)
      {:ok, {tensor, _}} = FFmpeg.load(uri, backend_config)

      {channels, frames} = Nx.shape(tensor)
      assert channels == 2
      assert_in_delta frames, 11_025, 25
    end

    test "handles channels_first option" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"

      {:ok, backend_config} = BackendReadConfig.validate(channels_first: false)
      {:ok, {tensor, _sample_rate}} = FFmpeg.load(uri, backend_config)

      assert Nx.shape(tensor) == {262_117, 2}
    end

    test "handles normalize option" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"

      {:ok, backend_config} = BackendReadConfig.validate(normalize: false)
      {:ok, {tensor, _sample_rate}} = FFmpeg.load(uri, backend_config)

      max_value = Nx.tensor(32_767)
      assert Nx.less_equal(Nx.reduce_max(Nx.abs(tensor)), max_value) == Nx.tensor(1, type: :u8)
    end

    test "should handle file not found" do
      assert {:error, %NxAudio.IO.Errors.InvalidMetadata{reason: :no_such_file}} =
               FFmpeg.load("file_not_found", [])
    end
  end

  describe "save/3" do
    @describetag :tmp_dir

    test "should be able to save a tensor to a wav file", %{tmp_dir: tmp_dir} do
      uri = Path.join([tmp_dir, "sine_wave.wav"])

      sample_rate = 22_050
      tensor = new_tensor(sample_rate)

      {:ok, backend_config} = BackendSaveConfig.validate(sample_rate: sample_rate)

      assert :ok == FFmpeg.save(uri, tensor, backend_config)

      assert {:ok,
              %NxAudio.IO.AudioMetadata{
                sample_rate: 22_050,
                num_frames: 22_050,
                num_channels: 1,
                bits_per_sample: 16,
                encoding: NxAudio.IO.Encoding.Type.PCM_S16
              }} == FFmpeg.info(uri)
    end

    test "should be able to save the tensor to a different codec based on the file name", %{
      tmp_dir: tmp_dir
    } do
      uri = Path.join([tmp_dir, "sine_wave.mp3"])

      sample_rate = 22_050
      tensor = new_tensor(sample_rate)

      {:ok, backend_config} = BackendSaveConfig.validate(sample_rate: sample_rate)

      assert :ok == FFmpeg.save(uri, tensor, backend_config)

      assert {:ok,
              %NxAudio.IO.AudioMetadata{
                bits_per_sample: 0,
                encoding: NxAudio.IO.Encoding.Type.MP3,
                num_channels: 1,
                num_frames: 15_114_240,
                sample_rate: 22_050
              }} == FFmpeg.info(uri)
    end
  end

  describe "info/1 - PCM Formats" do
    test "parses pcm_s16le" do
      uri = "test/fixtures/audio_samples/pcm_s16le.wav"

      expected = %AudioMetadata{
        sample_rate: 44_100,
        num_frames: 262_094,
        num_channels: 2,
        bits_per_sample: 16,
        encoding: NxAudio.IO.Encoding.Type.PCM_S16
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_s24le" do
      uri = "test/fixtures/audio_samples/pcm_s24le.wav"

      expected = %AudioMetadata{
        sample_rate: 44_100,
        num_frames: 262_094,
        num_channels: 1,
        bits_per_sample: 24,
        encoding: NxAudio.IO.Encoding.Type.PCM_S24
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_s32le" do
      uri = "test/fixtures/audio_samples/pcm_s32le.wav"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 32,
        encoding: NxAudio.IO.Encoding.Type.PCM_S32
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_u8" do
      uri = "test/fixtures/audio_samples/pcm_u8.wav"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 8,
        encoding: NxAudio.IO.Encoding.Type.PCM_U8
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_f32le" do
      uri = "test/fixtures/audio_samples/pcm_f32le.wav"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 32,
        encoding: NxAudio.IO.Encoding.Type.PCM_F32
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_f64le" do
      uri = "test/fixtures/audio_samples/pcm_f64le.wav"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 64,
        encoding: NxAudio.IO.Encoding.Type.PCM_F64
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_mulaw" do
      uri = "test/fixtures/audio_samples/mulaw.wav"

      expected = %AudioMetadata{
        bits_per_sample: 8,
        encoding: NxAudio.IO.Encoding.Type.ULAW,
        num_channels: 1,
        num_frames: 47_545,
        sample_rate: 8000
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses pcm_alaw" do
      uri = "test/fixtures/audio_samples/alaw.wav"

      expected = %AudioMetadata{
        bits_per_sample: 8,
        encoding: NxAudio.IO.Encoding.Type.ALAW,
        num_channels: 2,
        num_frames: 47_545,
        sample_rate: 8000
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end
  end

  describe "info/1 - Compressed Formats" do
    test "parses flac" do
      uri = "test/fixtures/audio_samples/compressed.flac"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 0,
        encoding: NxAudio.IO.Encoding.Type.FLAC
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses mp3" do
      uri = "test/fixtures/audio_samples/compressed.mp3"

      expected = %AudioMetadata{
        num_frames: 84_787_200,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 0,
        encoding: NxAudio.IO.Encoding.Type.MP3
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses vorbis" do
      uri = "test/fixtures/audio_samples/compressed.ogg"

      expected = %AudioMetadata{
        num_frames: 131_047,
        sample_rate: 22_050,
        num_channels: 1,
        bits_per_sample: 0,
        encoding: NxAudio.IO.Encoding.Type.VORBIS
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses opus" do
      uri = "test/fixtures/audio_samples/compressed.opus"

      expected = %AudioMetadata{
        num_frames: 285_896,
        sample_rate: 48_000,
        num_channels: 1,
        bits_per_sample: 0,
        encoding: NxAudio.IO.Encoding.Type.OPUS
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end

    test "parses AMR Narrow Band" do
      uri = "test/fixtures/audio_samples/narrow_band.amr"

      expected = %AudioMetadata{
        num_frames: 49_218,
        sample_rate: 8000,
        num_channels: 1,
        bits_per_sample: 0,
        encoding: NxAudio.IO.Encoding.Type.AMR_NB
      }

      assert {:ok, expected} == FFmpeg.info(uri)
    end
  end

  test "info/1 - Unknown Filetype" do
    uri = "test/fixtures/audio_samples/unknown_format.iff"

    expected = %AudioMetadata{
      bits_per_sample: 8,
      encoding: NxAudio.IO.Encoding.Type.UNKNOWN,
      num_channels: 1,
      num_frames: 47_545,
      sample_rate: 8000
    }

    assert {:ok, expected} == FFmpeg.info(uri)
  end

  test "info/1 - File not found" do
    uri = "test/fixtures/audio_samples/no_file.wav"

    assert {:error,
            %NxAudio.IO.Errors.InvalidMetadata{
              class: :invalid,
              reason: :no_such_file
            }} = FFmpeg.info(uri)
  end

  defp new_tensor(sample_rate) do
    time = Nx.tensor(Enum.map(0..(sample_rate - 1), fn x -> x / sample_rate end))
    frequency = 440.0

    time
    |> Nx.multiply(2 * :math.pi() * frequency)
    |> Nx.sin()
    |> Nx.multiply(32_767.0)
    |> Nx.new_axis(-1)
  end
end
