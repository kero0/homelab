{
  pkgs,
  sharesdir,
  ...
}:
{
  services.ollama = {
    enable = true;
    syncModels = true;
    host = "127.0.0.1";
    package = pkgs.ollama-vulkan;
    loadModels = [
      "gemma4:e4b"
      "gemma4:e2b"
      "qwen3.5:4b"
    ];
    models = "${sharesdir}/models";
    environmentVariables = {
      OLLAMA_MAX_LOADED_MODELS = "1";
    };
  };
}
