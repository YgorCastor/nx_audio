defmodule NxAudio.IO do
  @moduledoc """
  Defines a behaviour for audio backend operations
  """
  @moduledoc section: :io

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
end
