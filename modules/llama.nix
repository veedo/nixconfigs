{ inputs, self, ... }:
{
  flake.nixosModules.llama =
    { pkgs, lib, ... }:
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
              "-DGGML_CUDA_FA_ALL_QUANTS=ON"
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

      # Context windows, shared by the llama-swap server config and the opencode
      # client config below so the two cannot drift. llama-server rejects any
      # request larger than its window with a 400 (exceed_context_size_error),
      # so the client must be told the same numbers the server was started with.
      qwenCtx = 98304;
      gptOssCtx = 65536;
      # Qwen3.6-27B-A3B-Coder: the model card's suggested context is 32768, and
      # that is what is configured here. The architecture would allow far more
      # (trained for 262144, and its KV cache is cheap -- see below), so this is
      # a deliberate "use the suggested value" choice, not a VRAM limit.
      qwen36Ctx = 81920;
      qwen36ReasoningBudget = 10240;

      # Tokens reserved for a single response. This is NOT the context window:
      # opencode subtracts it from the window to decide how much room is left
      # for input, so window == output would leave no room for a prompt.
      # models.dev lists 32768 for both of these models.
      maxOutput = 32768;

      # qwen3.6-27b's whole window is only 32768, so it cannot reserve the same
      # 32768 for output -- that would leave zero room for the prompt. Half the
      # window still comfortably covers the model's 8192-token thinking budget
      # plus a long answer.
      qwen36Output = qwen36Ctx / 2;

      # Kept as its own derivation so the unit below can list it as a
      # restartTrigger. llama-swap reads this file once at startup and holds it
      # in memory, and its --watch-config poller cannot detect a rebuild (Nix
      # normalizes store mtimes to the epoch), so a config change only takes
      # effect if switch-to-configuration restarts the service.
      #
      # Sized for an RTX 5070 (12227 MiB VRAM, of which an idle desktop session
      # already holds ~1200 MiB) backed by 60 GB of system RAM. Both models are
      # mixture-of-experts, so the attention/dense tensors live on the GPU while
      # --n-cpu-moe pushes the bulk of the expert weights into RAM. llama-swap
      # keeps only one model resident at a time by default, which is what we
      # want with this little VRAM.
      #
      # Measured on this machine (nvidia-smi with the model loaded):
      #   gpt-oss-20b      --n-cpu-moe 10 -> 10009 MiB used, 1763 MiB free, 69 tok/s
      #   qwen3-coder-30b  --n-cpu-moe 34 -> 10715 MiB used, 1057 MiB free, 50 tok/s
      #   qwen3-coder-30b  --n-cpu-moe 38 ->  9266 MiB used, 2506 MiB free, 45 tok/s
      #
      # Context sizing for qwen (measured on this box, --flash-attn on):
      #   KV cache costs 52 KiB/token at q8_0, 27 KiB/token at q4_0.
      #   Each --n-cpu-moe layer moved off the GPU frees ~398 MiB.
      #   Fixed GPU cost (weights + compute buffers) is ~4838 MiB at moe 38.
      #   => usable ctx ~= (VRAM - desktop - headroom - fixed) / per-token cost
      # The desktop alone floats between 1090 and 1650 MiB depending on what is
      # open, so budget >=2 GB free rather than filling to the brim. Measured:
      #   ctx  65536 q8_0 moe 38 ->  9623 used, 2150 free, 51 tok/s
      #   ctx  81920 q8_0 moe 38 -> 10435 used, 1337 free, 51 tok/s  (too tight)
      #   ctx  98304 q8_0 moe 42 ->  9871 used, 1901 free, 47 tok/s   <- chosen
      #   ctx 131072 q4_0 moe 38 ->  9923 used, 1849 free, 51 tok/s   (KV quality
      #                              drops; q8_0 kept instead since this is the
      #                              coding model)
      # ctx 131072 at q8_0 does not fit at any moe setting worth using: it fails
      # with "failed to allocate buffer for kv cache". The model itself is
      # trained for 262144, so the ceiling here is VRAM, not the model.
      #
      # Sizing for qwen3.6-27b-coder is a different problem, because it is a
      # *hybrid* model (arch qwen35moe: 40 layers, but only every 4th is full
      # attention -- 10 attention layers and 30 gated-linear-attention layers).
      # Linear-attention layers carry a fixed-size recurrent state instead of a
      # growing KV cache, so context is nearly free here:
      #   KV = 10 layers * 2 kv-heads * 256 head-dim * 2 (K+V) = 10240 elem/token
      #      = 20 KiB/token at f16, i.e. 640 MiB for the whole 32768 window.
      #   Recurrent state adds a constant ~64 MiB regardless of context.
      # Compare qwen3-coder-30b's 52 KiB/token: this model's window costs about
      # 2.5% of what the same window would cost there. So --cache-type-k/v are
      # deliberately left at f16 -- quantizing would save ~300 MiB and cost
      # quality on the model we care most about being accurate.
      #
      # That makes *weights*, not KV, the binding constraint. CD-IQ4_K_M is
      # ~15.9 GiB, and each --n-cpu-moe layer moves one layer's 184 experts to
      # RAM. Measured on this machine (nvidia-smi during a 300-token
      # generation, desktop sitting at ~1.1-1.2 GiB):
      #   moe 22 -> 11509 used,  263 free            (will not survive the
      #                                               desktop growing -- unusable)
      #   moe 28 ->  9593 used, 2179 free, 70 tok/s
      #   moe 29 ->  9261 used, 2511 free, 76 tok/s   <- chosen
      # The slope between those points is ~332 MiB freed per layer, so the fixed
      # cost (non-expert weights + KV + CUDA compute buffers) is ~4.3 GiB --
      # noticeably heavier than qwen3-coder-30b's ~4.8 GiB at moe 38 relative to
      # how few experts stay resident. 28 measuring *slower* than 29 is
      # draft-acceptance noise (67% vs 79% below), not layer placement; the two
      # are the same speed within run-to-run variance, so 29 is free margin.
      # Range is 0-40, one per layer. Raise it if this ever OOMs.
      #
      # MTP: this repo ships the model's native multi-token-prediction head, so
      # --spec-type draft-mtp gives speculative decoding without a second draft
      # model. It pays off especially well here -- verifying several drafted
      # tokens in one batch amortises the expensive CPU-side expert matmuls that
      # --n-cpu-moe creates. --spec-draft-n-max 3 is the A3B recommendation.
      # Both flags need llama.cpp >= b9180; the pinned build is 10273. Measured
      # draft acceptance on real coding output is 67-79%, and llama-server
      # reports it per request as draft_n / draft_n_accepted in `timings` --
      # worth re-checking there rather than watching prompt-processing rate,
      # which MTP does not help.
      swapConfig = pkgs.writeText "llama-swap-config.yaml" ''
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
              --flash-attn on
              --ctx-size ${toString qwenCtx}
              --n-gpu-layers 99
              --n-cpu-moe 42
              --cache-type-k q8_0
              --cache-type-v q8_0
              --temp 0.7
              --top-p 0.8
              --top-k 20
              --repeat-penalty 1.05
            aliases:
              - coder
            ttl: 600

          # Coding / agentic work, newer generation. Qwen3.6-35B-A3B with its
          # expert count pruned 256 -> 184, so ~26B total and still ~3B active.
          # Hybrid attention (see the sizing notes above) and a native MTP head
          # for speculative decoding. CD-IQ4_K_M is the card's recommended quant
          # ("full-precision-parity code quality at the smallest at-parity
          # size"); the IQ2_M/IQ3_M quants are the ones to avoid on Blackwell.
          # Sampling and the 8192-token thinking budget are the card's suggested
          # values. Top-10 expert routing is baked into these weights; append
          #   --override-kv qwen35moe.expert_used_count=int:8
          # to trade a little quality for faster CPU-side expert passes.
          qwen36-coder-27b:
            cmd: |
              ''${llama-server}
              -hf ManniX-ITA/Qwen3.6-27B-A3B-Coder-MTP-GGUF:CD-IQ4_K_M
              --no-mmproj
              --flash-attn auto
              --ctx-size ${toString qwen36Ctx}
              --n-gpu-layers 99
              --n-cpu-moe 29
              --spec-type draft-mtp
              --spec-draft-n-max 3
              --reasoning-budget ${toString qwen36ReasoningBudget}
              --reasoning-budget-message "OK, I have enough to answer now."
              --temp 0.6
              --top-p 0.95
              --top-k 20
            aliases:
              - qwen36
              - coder36
            ttl: 600

          # Reasoning / debugging. MXFP4 weights (~11 GB) with a small expert
          # spill to RAM to leave room for the KV cache. Raise or lower effort
          # per request, or pin it here with:
          #   --chat-template-kwargs '{"reasoning_effort":"high"}'
          gpt-oss-20b:
            cmd: |
              ''${llama-server}
              -hf ggml-org/gpt-oss-20b-GGUF
              --flash-attn on
              --ctx-size ${toString gptOssCtx}
              --n-gpu-layers 99
              --n-cpu-moe 10
              --temp 1.0
              --top-p 1.0
              --top-k 0
            aliases:
              - reasoner
              - thinker
            ttl: 600
      '';

      # opencode's client-side view of the same two models. Lives here rather
      # than in its own module so it shares the ctx values above; the numbers
      # have to agree with what llama-server was started with.
      opencodeConfig = (pkgs.formats.json { }).generate "opencode.json" {
        "$schema" = "https://opencode.ai/config.json";
        provider."llama.cpp" = {
          npm = "@ai-sdk/openai-compatible";
          name = "llama-server (local)";
          options.baseURL = "http://127.0.0.1:9292/v1";
          models = {
            qwen3-coder-30b = {
              name = "Qwen3-Coder: a3b-30b (local)";
              limit = {
                context = qwenCtx;
                output = maxOutput;
              };
            };
            qwen36-coder-27b = {
              name = "Qwen3.6-Coder: a3b-27b (local)";
              limit = {
                context = qwen36Ctx;
                output = qwen36Output;
              };
            };
            gpt-oss-20b = {
              name = "GPT-oss: 20b (local)";
              limit = {
                context = gptOssCtx;
                output = maxOutput;
              };
            };
          };
        };
      };

      # Language servers for crush. These are launched with `nix shell` against
      # this flake's pinned nixpkgs-unstable rather than interpolated as bare
      # store paths. Interpolating a store path makes the server a runtime
      # dependency of crushrc, and therefore of the system closure -- so every
      # nixos-rebuild fetches the Go toolchain, rust-analyzer, Elixir/OTP and
      # node whether or not a single .go or .ex file is ever opened. `nix shell`
      # resolves the same derivation lazily on first use and lets the GC reclaim
      # it afterwards. Evaluation is still pinned to flake.lock, so this is no
      # less reproducible, and nix's eval cache keeps warm startup around 50 ms,
      # which is noise next to LSP initialization itself. The trade is that the
      # first launch of a server has to build or substitute it, so it needs
      # network access the first time.
      #
      # `nix shell ... --command <bin>` rather than `nix run`, for two reasons:
      # vscode-langservers-extracted ships four servers and sets no mainProgram,
      # so `nix run` cannot pick one; and --command swallows the remaining
      # arguments, so server flags like --stdio need no `--` separator.
      #
      # filetypes/rootMarkers keep a server from being started outside the kind
      # of project it understands. Without rootMarkers, rust-analyzer starts in
      # every repo and logs "failed to fetch workspace" wherever there is no
      # Cargo.toml.
      lspServers = {
        go = {
          attr = "gopls";
          bin = "gopls";
          # gopls does not live in the `go` derivation -- referencing
          # ${pkgs.go}/bin/gopls is what produced the original
          # "fork/exec ...: no such file or directory".
          filetypes = [
            "go"
            "gomod"
            "gowork"
            "gotmpl"
          ];
          rootMarkers = [
            "go.mod"
            "go.work"
          ];
        };

        # Deliberately not named "python" (nor "pylsp"/"python3"): crush drops an
        # `lsp add` entry under any of those names without logging anything, so
        # the entry this replaces never actually started. The name is only a
        # label -- filetypes below are what bind it to .py files.
        pythonls = {
          attr = "python3Packages.python-lsp-server";
          bin = "pylsp";
          filetypes = [ "python" ];
        };

        nix = {
          attr = "nil";
          bin = "nil";
          filetypes = [ "nix" ];
        };

        rust = {
          attr = "rust-analyzer";
          bin = "rust-analyzer";
          filetypes = [ "rust" ];
          rootMarkers = [ "Cargo.toml" ];
        };

        css = {
          attr = "vscode-langservers-extracted";
          bin = "vscode-css-language-server";
          args = [ "--stdio" ];
          filetypes = [
            "css"
            "scss"
            "less"
          ];
        };

        json = {
          attr = "vscode-langservers-extracted";
          bin = "vscode-json-language-server";
          args = [ "--stdio" ];
          filetypes = [
            "json"
            "jsonc"
          ];
        };

        # Not vscode-html-language-server: it advertises an LSP 3.18
        # workspace/textDocumentContent capability that crush's LSP client
        # cannot decode, and the handshake dies with "unmarshal failed to match
        # one of [TextDocumentContentOptions TextDocumentContentRegistrationOptions]".
        # Its css and json siblings above are unaffected.
        html = {
          attr = "superhtml";
          bin = "superhtml";
          args = [ "lsp" ];
          filetypes = [ "html" ];
        };

        # One server for both languages -- typescript-language-server handles
        # JavaScript too, and a second copy would just be another tsserver
        # process holding a duplicate program graph in memory.
        typescript = {
          attr = "typescript-language-server";
          bin = "typescript-language-server";
          args = [ "--stdio" ];
          filetypes = [
            "typescript"
            "typescriptreact"
            "javascript"
            "javascriptreact"
          ];
        };

        # nixpkgs' elixir-ls is a launcher script that runs Mix.install at
        # startup to build itself, which needs a working Hex install and fails
        # closed here ("Could not start Hex", then the LSP handshake times out).
        # expert is the successor upstream now points lexical and next-ls at,
        # and it ships as a real binary.
        elixir = {
          attr = "beamPackages.expert";
          bin = "expert";
          args = [ "--stdio" ];
          filetypes = [
            "elixir"
            "eelixir"
            "heex"
            "surface"
          ];
          rootMarkers = [ "mix.exs" ];
        };
      };

      # crushrc is a bash script, so this renders each server as an `lsp add`
      # call. Uses the system profile's nix rather than ${pkgs.nix} so the
      # client always matches the daemon the user's own shell talks to.
      renderLsp =
        name: srv:
        let
          shellArgs = [
            "shell"
            "--quiet"
            "${inputs.nixpkgs-unstable}#${srv.attr}"
            "--command"
            srv.bin
          ]
          ++ srv.args or [ ];
          line = flag: values: lib.concatMapStringsSep " " (v: ''--${flag} "${v}"'') values;
          lines = [
            ''--command "/run/current-system/sw/bin/nix"''
            (line "args" shellArgs)
          ]
          ++ lib.optional (srv.filetypes or [ ] != [ ]) (line "filetypes" srv.filetypes)
          ++ lib.optional (srv.rootMarkers or [ ] != [ ]) (line "root-markers" srv.rootMarkers);
        in
        ''
          lsp add ${name} \
            ${lib.concatStringsSep " \\\n  " lines}
        '';

      # Crush configuration for local llama.cpp models
      crushConfig = pkgs.writeText "crushrc" ''
        export CRUSH_DISABLE_METRICS=1

        permissions allow \
          view ls grep glob sourcegraph \
          edit write multiedit \
          fetch agentic_fetch

        hook add PreToolUse --matcher "^bash$" --command "/usr/bin/rtk-rewrite"

        provider add llamacpp \
          --name "llama.cpp" \
          --type llamacpp \
          --base-url "http://localhost:9292/v1" \
          --discover-models true

        model add llamacpp/qwen3-coder-30b \
          --name "Qwen3-Coder: a3b-30b (local)" \
          --context-window ${toString qwenCtx} \
          --default-max-tokens ${toString maxOutput}

        model add llamacpp/qwen36-coder-27b \
          --name "Qwen3.6-Coder: a3b-27b (local)" \
          --context-window ${toString qwen36Ctx} \
          --default-max-tokens ${toString qwen36Output}

        # LSPs for various languages, fetched on demand via nix (see lspServers).
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderLsp lspServers)}
      '';
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

      environment.etc."llama-swap/config.yaml".source = swapConfig;

      # No home-manager in this flake, so link the generated opencode config into
      # place with tmpfiles (re-applied on every switch). "L+" replaces whatever
      # is already at that path. Only opencode.json is managed -- opencode also
      # keeps node_modules/, package.json and skills/ in that directory and
      # rewrites them itself, so the directory as a whole must stay writable.
      systemd.tmpfiles.rules = [
        "d /home/zandere/.config/opencode 0755 zandere users -"
        "L+ /home/zandere/.config/opencode/opencode.json - - - - ${opencodeConfig}"
        "d /home/zandere/.config/crush 0755 zandere users -"
        "L+ /home/zandere/.config/crush/crushrc - - - - ${crushConfig}"
      ];

      # Reachable over the tailnet only -- deliberately not in the global
      # allowedTCPPorts, since the API is unauthenticated.
      networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 9292 ];

      systemd.services.llama-swap = {
        description = "llama-swap - OpenAI compatible proxy with automatic model swapping";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        # Pick up model/flag changes on nixos-rebuild switch. Without this the
        # daemon keeps serving the config it started with.
        restartTriggers = [ swapConfig ];

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
