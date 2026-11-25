{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  home = {
    username = "nikita";
    sessionPath = [
      "${config.home.homeDirectory}/nix/scripts"
      "${config.home.homeDirectory}/.local/bin"
    ];
    sessionVariables = {
      EDITOR = "ttyed";
      VISUAL = "ttyed";
    };
    shellAliases = {
      e = "ttyed --";
      nvim = "env NVIM_APPNAME=nvim nvim";
      lazy = "env NVIM_APPNAME=lazy nvim";
      vim = "vim -XY";
      em = "emacsclient -t";
    };
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

  programs =
    let
      vimCommon = ''
        set nu
        set ai
        set tabstop=4
        set shiftwidth=4
      '';
    in
    {
      zsh = {
        enable = true;
        package = pkgs.zsh;
        dotDir = config.home.homeDirectory;
        defaultKeymap = "emacs";
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

      neovim = {
        enable = true;

        # LazyVim's generated init loads lazy.nvim directly from the Nix store.
        # Avoid also installing it into the lean personality's package directory.
        plugins = lib.mkForce [ ];
        extraConfig = vimCommon;
      };

      vim = {
        enable = true;
        plugins = [ pkgs.vimPlugins.vim-sensible ];
        extraConfig = vimCommon;
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
        baseIndex = 1;
        disableConfirmationPrompt = true;
        mouse = true;
        newSession = true;
        shortcut = "a";
        terminal = "xterm-ghostty";
        sensibleOnTop = true;
      };

      lazyvim = {
        enable = true;
        appName = "lazy";

        installCoreDependencies = false;

        extras = {
          lang = {
            nix.enable = true;
            clangd.enable = true;
            git.enable = true;
            json = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
            toml = {
              enable = true;
              installDependencies = true;
              installRuntimeDependencies = true;
            };
          };

          editor = {
            snacks-picker.enable = true;
            snacks-explorer.enable = true;
          };
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

          # need this to prevent a race where lualine loads before troubles done
          lualine-trouble = ''
            return {
              "nvim-lualine/lualine.nvim",
              dependencies = {
                "folke/trouble.nvim",
              },
            }
          '';

          # lazyvim-nix names dev-path dirs owner--repo, so lazy.nvim can't map
          # require("conform") back to its spec and never runs setup() -> no
          # formatters, no format on save. Load it eagerly until upstream fixes
          # it: https://github.com/pfassina/lazyvim-nix/issues/117
          conform-eager = ''
            return {
              "stevearc/conform.nvim",
              lazy = false,
            }
          '';
        };

        config.options = ''
           -- vim.cmd.source(${builtins.toJSON "${config.xdg.configHome}/vim/shared.vim"})

          vim.opt.relativenumber = false

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
          lazygit
          lua-language-server
          lua51Packages.luarocks
          lua5_1
          mermaid-cli
          shfmt
          statix
          stylua
          tectonic
          tree-sitter
        ];
      };
      # Let Home Manager install and manage itself.
      home-manager.enable = true;
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
}
