defmodule NxAudio.Commons.Errors.Unknown do
  @moduledoc """
  Errors that are unknown or unclassified
  """
  use Splode.ErrorClass, class: :unknown

  defmodule UnknownError do
    @moduledoc """
    Default unexpected error
    """
    use Splode.Error, class: :unknown

    def message(%{error: error}) do
      if is_binary(error) do
        to_string(error)
      else
        inspect(error)
      end
    end
  end
end
