defmodule NxAudio.IO.BackendReadConfig do
  @moduledoc """
  Defines how the backend should read the audio file.
  """
  @moduledoc section: :io

  @schema NimbleOptions.new!(
            frame_offset: [
              type: :non_neg_integer,
              default: 0,
              doc: "Number of frames to skip before start reading data"
            ],
            num_frames: [
              type: :integer,
              default: -1,
              doc: """
              Maximum number of frames to read. -1 reads all the remaining samples, starting from frame_offset. 
              This function may return the less number of frames if there is not enough frames in the given file
              """
            ],
            normalize: [
              type: :boolean,
              default: true,
              doc: """
              When true, this function converts the native sample type to float32. Default: true.

              If input file is integer WAV, giving False will change the resulting Tensor type to integer type. This argument has no effect for formats other than integer WAV type.
              """
            ],
            channels_first: [
              type: :boolean,
              default: true,
              doc: """
              When True, the returned Tensor has dimension [channel, time]. Otherwise, the returned Tensor’s dimension is [time, channel].
              """
            ],
            buffer_size: [
              type: :integer,
              default: 4096,
              doc: """
              Size of buffer to use when processing file-like objects, in bytes.
              """
            ],
            backend: [type: :atom]
          )

  alias NxAudio.IO.Errors

  @typedoc """
  #{NimbleOptions.docs(@schema)}  
  """
  @type t() :: [unquote(NimbleOptions.option_typespec(@schema))]

  @doc """
  Parses and validate a keyword list into a valid audio backend config
  """
  @spec validate(backend_options :: Keyword.t()) ::
          {:ok, t()} | {:error, Errors.InvalidBackendConfigurations.t()}
  def validate(config) do
    case NimbleOptions.validate(config, @schema) do
      {:ok, parsed_config} ->
        {:ok, parsed_config}

      {:error, error} ->
        {:error, Errors.InvalidBackendConfigurations.exception(message: error.message)}
    end
  end
end
