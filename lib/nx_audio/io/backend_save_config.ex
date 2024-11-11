defmodule NxAudio.IO.BackendSaveConfig do
  @moduledoc """
  Defines how the backend should save the audio tensor.
  """
  @moduledoc section: :io

  @schema NimbleOptions.new!(
            sample_rate: [
              type: :non_neg_integer,
              required: true,
              doc: "Which sampling rate to use when writing the file"
            ],
            channels_first: [
              type: :boolean,
              default: true,
              doc: """
              If true, the given tensor is interpreted as [channel, time], otherwise [time, channel]
              """
            ],
            format: [
              type: {:in, [:wav, :flac, :ogg]},
              doc: """
              Override the audio format. When uri argument is path-like object, audio format is inferred from file extension. 
              If the file extension is missing or different, you can specify the correct format with this argument.
              When uri argument is file-like object, this argument is required.
              """
            ],
            encoding: [
              type: {:in, NxAudio.IO.Encoding.Type.enums()},
              doc: """
              Changes the encoding for supported formats. This argument is effective only for supported formats, i.e. "wav" and "flac"
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
