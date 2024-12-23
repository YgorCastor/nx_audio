defmodule NxAudio.Commons.Errors do
  @moduledoc false
  use Splode,
    error_classes: [
      invalid: NxAudio.Commons.Errors.Invalid,
      io: NxAudio.Commons.Errors.IO,
      framework: NxAudio.Commons.Errors.Framework,
      unknown: NxAudio.Commons.Errors.Unknown
    ],
    unknown_error: NxAudio.Commons.Errors.Unknown.UnknownError
end
