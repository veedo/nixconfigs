{ inputs, self, ... }:
{
  flake.nixosModules.llama =
    { pkgs, ... }:
    let
      # Native-optimized CUDA build of llama.cpp, shared between the system
      # profile and the llama-swap config below.
      llama-cpp =
        (pkgs.unstable.llama-cpp.override {
          cudaSupport = true;
          rocmSupport = false;
          metalSupport = false;
          # Enable BLAS for optimized CPU layer performance (OpenBLAS)
          blasSupport = true;
        }).overrideAttrs
          (oldAttrs: {
            # Enable native CPU optimizations (AVX, AVX2, etc.)
            cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
              "-DGGML_NATIVE=ON"
              # nixpkgs defaults to every capability CUDA 12.9 supports, which
              # means nine ggml-cuda compile passes. GGML_NATIVE already pins
              # this build to one machine, so target only the RTX 5070's
              # Blackwell arch (sm_120). Last -D on the command line wins.
              "-DCMAKE_CUDA_ARCHITECTURES=120"
            ];
            # Disable Nix's march=native stripping
            preConfigure = ''
              export NIX_ENFORCE_NO_NATIVE=0
              ${oldAttrs.preConfigure or ""}
            '';
          });

      # Weights are pulled on first use by llama.cpp's -hf flag and cached here.
      modelCache = "/var/lib/llama-swap/models";
    in
    {
      # perSystem's overlay only reaches flake-parts' pkgs, so expose `unstable`
      # to the NixOS configuration here as well.
      nixpkgs.overlays = [
        (final: prev: {
          unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv.hostPlatform) system;
            config.allowUnfree = true;
          };
        })
      ];

      environment.systemPackages = [
        llama-cpp
        pkgs.unstable.llama-swap
      ];

      # Sized for an RTX 5070 (12 GB VRAM) backed by 60 GB of system RAM. Both
      # models are mixture-of-experts, so the attention/dense tensors live on the
      # GPU while --n-cpu-moe pushes the bulk of the expert weights into RAM.
      # llama-swap keeps only one model resident at a time by default, which is
      # what we want with this little VRAM.
      environment.etc."llama-swap/config.yaml".text = ''
        healthCheckTimeout: 1800
        logLevel: info
        startPort: 10001

        macros:
          llama-server: >
            ${llama-cpp}/bin/llama-server
            --host 127.0.0.1
            --port ''${PORT}
            --jinja
            --metrics

        models:
          # Coding / agentic work. 30B total but only 3B active per token, so it
          # stays responsive even with most experts on the CPU. ~18 GB of weights.
          qwen3-coder-30b:
            cmd: |
              ''${llama-server}
              -hf unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF:Q4_K_M
              --ctx-size 65536
              --n-gpu-layers 99
              --n-cpu-moe 30
              --cache-type-k q8_0
              --cache-type-v q8_0
              --temp 0.7
              --top-p 0.8
              --top-k 20
              --repeat-penalty 1.05
            aliases:
              - coder
            ttl: 600

          # Reasoning / debugging. MXFP4 weights (~11 GB) with a small expert
          # spill to RAM to leave room for the KV cache. Raise or lower effort
          # per request, or pin it here with:
          #   --chat-template-kwargs '{"reasoning_effort":"high"}'
          gpt-oss-20b:
            cmd: |
              ''${llama-server}
              -hf ggml-org/gpt-oss-20b-GGUF
              --ctx-size 65536
              --n-gpu-layers 99
              --n-cpu-moe 6
              --temp 1.0
              --top-p 1.0
              --top-k 0
            aliases:
              - reasoner
              - thinker
            ttl: 600
      '';

      # Reachable over the tailnet only -- deliberately not in the global
      # allowedTCPPorts, since the API is unauthenticated.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9292 ];

      systemd.services.llama-swap = {
        description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = "zandere";
          Group = "users";
          # Point to your declarative config file
          ExecStart = "${pkgs.unstable.llama-swap}/bin/llama-swap --config /etc/llama-swap/config.yaml --listen 0.0.0.0:9292 --watch-config";
          Restart = "always";
          RestartSec = 10;

          # /var/lib/llama-swap{,/models}, owned by the service user
          StateDirectory = "llama-swap/models";

          # Environment for CUDA support
          Environment = [
            "PATH=/run/current-system/sw/bin"
            "LD_LIBRARY_PATH=/run/opengl-driver/lib:/run/opengl-driver-32/lib"
            "HOME=/var/lib/llama-swap"
            "LLAMA_CACHE=${modelCache}"
          ];
        };
      };
    };
}
