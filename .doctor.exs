%Doctor.Config{
  ignore_modules: [
    NxAudio.IO.Encoding.Type,
    NxAudio.IO.Encoding.Type.ALAW,
    NxAudio.IO.Encoding.Type.AMR_NB,
    NxAudio.IO.Encoding.Type.AMR_WB,
    NxAudio.IO.Encoding.Type.FLAC,
    NxAudio.IO.Encoding.Type.MP3,
    NxAudio.IO.Encoding.Type.OPUS,
    NxAudio.IO.Encoding.Type.PCM_F32,
    NxAudio.IO.Encoding.Type.PCM_F64,
    NxAudio.IO.Encoding.Type.PCM_S8,
    NxAudio.IO.Encoding.Type.PCM_S16,
    NxAudio.IO.Encoding.Type.PCM_S24,
    NxAudio.IO.Encoding.Type.PCM_S32,
    NxAudio.IO.Encoding.Type.PCM_U8,
    NxAudio.IO.Encoding.Type.ULAW,
    NxAudio.IO.Encoding.Type.VORBIS,
    NxAudio.IO.Encoding.Type.HTK,
    NxAudio.IO.Encoding.Type.UNKNOWN,
    NxAudio.Visualizations.Spectrogram
  ],
  ignore_paths: [
    ~r|test/.*|
  ],
  min_module_doc_coverage: 40,
  min_module_spec_coverage: 0,
  min_overall_doc_coverage: 50,
  min_overall_moduledoc_coverage: 100,
  min_overall_spec_coverage: 0,
  exception_moduledoc_required: true,
  raise: false,
  reporter: Doctor.Reporters.Full,
  struct_type_spec_required: true,
  umbrella: false,
  failed: false
}
