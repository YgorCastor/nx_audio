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
  @type input_uri() :: binary() | Path.t()

  @type load_errors() :: NxAudio.IO.Errors.FailedToExecuteBackend.t()

  @doc """
  Loads an audio file from a given URI and returns a tuple with the audio tensor and the sample rate.
  """
  @callback load(uri :: input_uri(), config :: NxAudio.IO.BackendConfig.t()) ::
              {:ok, {audio_tensor(), sample_rate()}} | {:error, load_errors()}

  @callback info(uri :: input_uri()) :: {:ok, NxAudio.IO.AudioMetadata.t()} | {:error, term()}
end
