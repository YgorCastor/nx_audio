# NxAudio

NxAudio is an Elixir library for working with audio tensors, providing functionality similar to Python's torchaudio
but built for the Nx ecosystem.

## Features

* Audio I/O operations with support for multiple formats
* Audio transformations and processing
* Spectrogram visualizations
* Multiple codec support including:
  * PCM formats (S16, S24, S32, S8, U8, F32, F64)
  * FLAC
  * MP3
  * Vorbis
  * Opus
  * AMR (NB/WB)
  * μ-law and A-law
  * HTK

## Installation

Add `nx_audio` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nx_audio, "~> 0.1.0"}
  ]
end
```

## Dependencies

NxAudio requires:
* Elixir ~> 1.17
* FFmpeg for audio processing capabilities
* Nx for tensor operations

## Usage Examples

Basic audio operations:

```elixir
# Reading an audio file
{:ok, tensor, sample_rate} = NxAudio.IO.load("path/to/audio.mp3")

# Processing audio with transformations
transformed = NxAudio.Transforms.apply_window(tensor, :hann)

# Generating spectrograms
spectrogram = NxAudio.Transforms.spectrogram(tensor, sample_rate: sample_rate)
```

## Documentation

Detailed documentation is organized into the following sections:
* IO - Audio file reading/writing operations
* Transformations - Audio signal processing functions
* Visualizations - Spectrogram and waveform visualization tools
* Codecs - Supported audio format encodings

For more examples and detailed API documentation, visit the [official documentation](https://hexdocs.pm/nx_audio).

## License

This project is licensed under the MIT License.
