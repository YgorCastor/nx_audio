defmodule NxAudio.IO do
  @moduledoc """
  Defines a behaviour for audio backend operations
  """
  @moduledoc section: :io

  alias NxAudio.IO.{BackendReadConfig, BackendSaveConfig}

  @typedoc """
  Audio sample rate in Hz
  """
  @type sample_rate() :: non_neg_integer()

  @typedoc """
  A 2D tensor representing audio data. By default,
  the first dimension is the amount of channels and the second dimension is the amount of samples.
  """
  @type audio_tensor() :: Nx.Tensor.t()

  @typedoc """
  Defines the input for the load function, which can be a binary audio or a valid file path
  """
  @type file_uri() :: binary() | Path.t()

  @typedoc """
  Defines the possible errors that can occur when loading an audio file
  """
  @type io_errors() ::
          NxAudio.IO.Errors.FailedToExecuteBackend.t()
          | NxAudio.IO.Errors.InvalidMetadata.t()

  @doc """
  Loads an audio file from a given URI and returns a tuple with the audio tensor and the sample rate.
  """
  @callback load(uri :: file_uri(), config :: NxAudio.IO.BackendReadConfig.t()) ::
              {:ok, {audio_tensor(), sample_rate()}} | {:error, io_errors()}

  @doc """
  Streams an audio file from a given URI and returns an enumerable with the audio tensor and the sample rate.
  """
  @callback stream!(uri :: file_uri(), config :: NxAudio.IO.BackendReadConfig.t()) ::
              Enumerable.t()

  @doc """
  Saves an audio tensor to a given URI.
  """
  @callback save(
              uri :: file_uri(),
              tensor :: audio_tensor(),
              config :: NxAudio.IO.BackendSaveConfig.t()
            ) ::
              :ok | {:error, io_errors()}

  @doc """
  Returns the audio metadata for a given file.
  """
  @callback info(uri :: file_uri()) ::
              {:ok, NxAudio.IO.AudioMetadata.t()} | {:error, io_errors()}

  @doc """
  Loads an audio file from the given URI using the configured backend.

  ## Parameters
    * `uri` - The file path or binary audio data to load
    * `config` - The configuration for reading the audio file (see `NxAudio.IO.BackendReadConfig`)

  ## Returns
    * `{:ok, {tensor, sample_rate}}` - On success, returns a tuple with the audio tensor and sample rate
    * `{:error, error}` - On failure, returns an error struct
  """
  def load(uri, config) do
    with {:ok, config} <- BackendReadConfig.validate(config),
         module <- which_backend(config) do
      module.load(uri, config)
    end
  end

  @doc """
  Streams an audio file from the given URI using the configured backend.
  
  This function returns an enumerable that can be used to process the audio data in chunks,
  which is useful for handling large audio files without loading them entirely into memory.

  ## Parameters
    * `uri` - The file path or binary audio data to stream
    * `config` - The configuration for reading the audio file (see `NxAudio.IO.BackendReadConfig`)

  ## Returns
    * An `Enumerable.t()` that yields audio chunks
    
  ## Raises
    * Raises an error if the streaming operation fails
  """
  def stream!(uri, config) do
    with {:ok, config} <- BackendReadConfig.validate(config),
         module <- which_backend(config) do
      module.stream!(uri, config)
    end
  end

  @doc """
  Saves an audio tensor to a file at the specified URI using the configured backend.

  ## Parameters
    * `uri` - The target file path where the audio will be saved
    * `tensor` - The audio tensor to save (2D tensor with channels x samples)
    * `config` - The configuration for saving the audio file (see `NxAudio.IO.BackendSaveConfig`)

  ## Returns
    * `:ok` - On successful save
    * `{:error, error}` - On failure, returns an error struct
  """
  def save(uri, tensor, config) do
    with {:ok, config} <- BackendSaveConfig.validate(config),
         module <- which_backend(config) do
      module.save(uri, tensor, config)
    end
  end

  @doc """
  Retrieves metadata information about an audio file at the specified URI.

  ## Parameters
    * `uri` - The file path of the audio file to analyze
    * `config` - The configuration for reading the audio file (see `NxAudio.IO.BackendReadConfig`)

  ## Returns
    * `{:ok, metadata}` - On success, returns the audio metadata (see `NxAudio.IO.AudioMetadata`)
    * `{:error, error}` - On failure, returns an error struct
  """
  def info(uri, config) do
    with {:ok, config} <- BackendReadConfig.validate(config),
         module <- which_backend(config) do
      module.info(uri)
    end
  end

  defp which_backend(config) do
    case config[:backend] do
      :ffmpeg -> NxAudio.IO.Backends.FFmpeg
    end
  end
end
