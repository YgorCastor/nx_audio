defmodule NxAudio.IO.BackendReadConfigTest do
  use ExUnit.Case, async: true

  test "an empty config should return default values" do
    assert {:ok,
            [
              buffer_size: 4096,
              channels_first: true,
              normalize: true,
              num_frames: -1,
              frame_offset: 0
            ]} = NxAudio.IO.BackendReadConfig.validate([])
  end

  test "should return an error when a invalid value is informed" do
    assert {:error, %NxAudio.IO.Errors.InvalidBackendConfigurations{message: message}} =
             NxAudio.IO.BackendReadConfig.validate(
               buffer_size: -1,
               channels_first: 1,
               num_frames: 1.1
             )

    assert message =~ "invalid value for"
  end
end
