{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home = {
    username = "nikita";
    file = {
      ".emacs".source = ./emacs/.emacs;
      ".emacs.d/acme-mouse.el".source = ./emacs/acme-mouse.el;
    };
  };

  imports = [
    inputs.lazyvim.homeManagerModules.default
    inputs.nix-index-database.homeModules.default
    ./modules/nixpkgs-suggest.nix
  ];

  services.nixpkgsFirefoxSuggest.enable = true;

  home.packages = [ pkgs.pure-prompt ];

  programs = {
    zsh = {
      enable = true;
      package = pkgs.zsh;
      dotDir = config.home.homeDirectory;
      autosuggestion = {
        enable = true;
        strategy = [
          "match_prev_cmd"
          "completion"
        ];
      };
      autocd = true;
      enableVteIntegration = true;
      history = {
        append = true;
        expireDuplicatesFirst = true;
        findNoDups = true;
        ignoreAllDups = true;
        saveNoDups = true;
      };
      syntaxHighlighting.enable = true;
      shellAliases = {
        e = "nvim";
      };
      initContent = ''
        if [[ -z $AI_AGENT$CLAUDECODE$CURSOR_AGENT$GEMINI_CLI$OPENCODE ]]; then
          autoload -U promptinit && promptinit
          prompt pure
        fi

        setopt AUTO_MENU AUTO_LIST LIST_AMBIGUOUS LIST_PACKED LIST_TYPES \
        BAD_PATTERN HIST_REDUCE_BLANKS CORRECT CORRECT_ALL AUTO_RESUME \
        LONG_LIST_JOBS 
      '';
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
      tmux.enableShellIntegration = true;
    };

    nix-index = {
      enable = true;
      enableZshIntegration = true;
      # Both wrapped tools use the store database; do not also link the full index.
      symlinkToCacheHome = false;
      package =
        inputs.nix-index-database.packages.${pkgs.stdenv.hostPlatform.system}.nix-index-with-small-db;
    };
    nix-index-database.comma.enable = true;

    tmux = {
      enable = true;
      aggressiveResize = true;
      baseIndex = 1;
      disableConfirmationPrompt = true;
      focusEvents = true;
      mouse = true;
      newSession = true;
      shortcut = "a";
      terminal = "xterm-ghostty";
      sensibleOnTop = true;
    };

    lazyvim = {
      enable = true;

      extras.lang = {
        nix.enable = true;
      };

      pluginSource = "nixpkgs";

      plugins = {
        # adding sqlite to extraPackages doesnt work, needs this
        snacks-config = ''
          return {
            "folke/snacks.nvim",
            opts = {
              image = {
                enabled = true,
              },
              statuscolumn = {
                enabled = true,
              },
              picker = {
                db = {
                  sqlite3_path = "${pkgs.lib.getLib pkgs.sqlite}/lib/libsqlite3${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}",
                },
              },
            },
          }
        '';

        # nil config for importing flake inputs, silences prompt.
        # autoEvalInputs might be slow, set to false if so
        nix-lsp = ''
          return {
            "neovim/nvim-lspconfig",
            opts = {
              servers = {
                nil_ls = {
                  settings = {
                    ["nil"] = {
                      nix = {
                        flake = {
                          autoArchive = true,
                          autoEvalInputs = true,
                          nixpkgsInputName = true,
                        },
                      },
                    },
                  },
                },
              },
            },
          }
        '';

        # need this to prevent a race where lualine loads before troubles done
        lualine-trouble = ''
          return {
            "nvim-lualine/lualine.nvim",
            dependencies = {
              "folke/trouble.nvim",
            },
          }
        '';
      };

      config.options = ''
              -- Use Nix-provided Lua 5.1/LuaRocks, retaining rock support.
        local rocks = require("lazy.core.config").options.rocks
        rocks.enabled = true
        rocks.hererocks = false

            -- Norg is packaged separately from nvim-treesitter's supported parsers.
            vim.opt.rtp:append(
              "${pkgs.neovimUtils.grammarToPlugin pkgs.tree-sitter-grammars.tree-sitter-norg}"
            )

            -- Actually use Snacks' status column.
            vim.opt.statuscolumn = [[%!v:lua.require'snacks.statuscolumn'.get()]]
      '';

      treesitterParsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
        css
        latex
        scss
        svelte
        typst
        vue
      ];

      extraPackages = with pkgs; [
        alejandra
        ast-grep
        ghostscript
        imagemagick
        lua-language-server
        lua51Packages.luarocks
        lua5_1
        mermaid-cli
        nil
        nixd
        shfmt
        statix
        stylua
        tectonic
        tree-sitter
      ];
    };
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "25.11";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
