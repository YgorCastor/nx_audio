defmodule NxAudio.Transforms.AmplitudeToDb do
  @moduledoc """
  Represents the amplitude to decibel transformation for audio signals.
  """
  @moduledoc section: :transforms

  import Nx.Defn

  @behaviour NxAudio.Transforms

  @doc """
  Returns the decibel representation of a power or magnitude spectrogram.  

  ## Options  
  top_db: float() - The maximum decibel value. Default is 80.0.
  """
  @impl true
  @spec transform(NxAudio.IO.audio_tensor(), keyword()) ::
          NxAudio.IO.audio_tensor()
  defn transform(spectrogram, opts \\ []) do
    opts = keyword!(opts, top_db: 80.0, scale: :power)

    # Avoid log of zero
    spectrogram = Nx.max(spectrogram, 1.0e-10)

    db_values =
      case opts[:scale] do
        :power ->
          # dB for a power spectrogram = 10 * log10(power)
          Nx.multiply(10.0, Nx.log10(spectrogram))

        :magnitude ->
          # dB for a magnitude spectrogram = 20 * log10(amplitude)
          Nx.multiply(20.0, Nx.log10(spectrogram))

        other ->
          raise ArgumentError,
                "Invalid :scale option #{inspect(other)}. " <>
                  "Expected :power or :magnitude."
      end

    # Clamp the dynamic range
    db_max = Nx.reduce_max(db_values)
    min_db = db_max - opts[:top_db]
    Nx.max(db_values, min_db)
  end
end
