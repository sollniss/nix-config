{ config, lib, ... }:
# eza, broot and yazi use slightly different colors for the same concepts
# (directories, permissions, file types, owners, ...).
# Here we take over theming for the three tools and
# render all of them from a single semantic color map, derived from the live
# catppuccin palette so it still follows `catppuccin.flavor`/`catppuccin.accent`.
let
  cat = config.catppuccin;
  inherit (cat) flavor accent sources;

  palette = (lib.importJSON "${sources.palette}/palette.json").${flavor}.colors;

  # catppuccin palette color name -> "#rrggbb"
  col = name: palette.${name}.hex;
  # catppuccin palette color name -> "rgb(r, g, b)" (broot's color syntax)
  rgb =
    name:
    let
      p = palette.${name}.rgb;
    in
    "rgb(${toString p.r}, ${toString p.g}, ${toString p.b})";

  # Semantic role -> catppuccin palette color name. Only genuine roles live
  # here. Anything that isn't conceptually one of these roles references the
  # palette directly with `col`/`rgb` instead of borrowing an unrelated role.
  # `accent` follows config.catppuccin.accent (mauve by default).
  sem = {
    # text
    fg = "text";
    fgMuted = "subtext0";
    punct = "overlay0";
    accent = accent;

    # file kinds
    directory = accent;
    file = "text";
    symlink = "blue";
    executable = "green";
    special = accent;
    device = "maroon";
    pipe = "subtext1";

    # permissions
    permType = "blue";
    permRead = "yellow";
    permWrite = "red";
    permExec = "green";
    permNone = "surface2";

    # ownership
    owner = "peach";
    group = "subtext0";
    root = "red";

    # git
    gitAdded = "green";
    gitModified = "yellow";
    gitDeleted = "red";
    gitRenamed = "blue";
    gitIgnored = "overlay0";
    gitConflict = "maroon";

    # listing metadata
    date = "subtext0";
    size = "subtext0";

    # file-type categories
    image = "yellow";
    video = "peach";
    audio = "green";
    archive = "pink";
    document = "text";
    source = "blue";
  };

  # semantic role -> color, in each tool's required format
  hex = role: col sem.${role};
  RGB = role: rgb sem.${role};

  # broot colors files only structurally in its skin (so e.g. images render as
  # the plain `file` color). eza (`file_type`) and yazi (`[filetype]`) instead
  # color by category, so replicate that for broot via its `ext_colors` map.
  extColors =
    (lib.genAttrs [
      "jpg"
      "jpeg"
      "jpe"
      "jfif"
      "png"
      "gif"
      "bmp"
      "svg"
      "svgz"
      "webp"
      "ico"
      "tif"
      "tiff"
      "avif"
      "heic"
      "heif"
      "jxl"
      "ppm"
      "pgm"
      "pbm"
      "xpm"
    ] (_: RGB "image"))
    // (lib.genAttrs [
      "mp4"
      "m4v"
      "mkv"
      "webm"
      "mov"
      "avi"
      "flv"
      "wmv"
      "mpg"
      "mpeg"
      "m2v"
      "ogv"
      "3gp"
    ] (_: RGB "video"))
    // (lib.genAttrs [
      "mp3"
      "flac"
      "wav"
      "ogg"
      "oga"
      "opus"
      "m4a"
      "aac"
      "wma"
      "aiff"
      "ape"
      "mid"
      "midi"
    ] (_: RGB "audio"))
    // (lib.genAttrs [
      "zip"
      "tar"
      "gz"
      "tgz"
      "xz"
      "txz"
      "bz2"
      "tbz"
      "tbz2"
      "7z"
      "rar"
      "zst"
      "tzst"
      "lz"
      "lz4"
      "lzma"
      "lzo"
    ] (_: RGB "archive"));

  ezaTheme = ''
    colourful: true

    filekinds:
      normal: {foreground: "${hex "file"}"}
      directory: {foreground: "${hex "directory"}"}
      symlink: {foreground: "${hex "symlink"}"}
      pipe: {foreground: "${hex "pipe"}"}
      block_device: {foreground: "${hex "device"}"}
      char_device: {foreground: "${hex "device"}"}
      socket: {foreground: "${col "subtext1"}"}
      special: {foreground: "${hex "special"}"}
      executable: {foreground: "${hex "executable"}"}
      mount_point: {foreground: "${col "blue"}"}

    perms:
      user_read: {foreground: "${hex "permRead"}", is_bold: true}
      user_write: {foreground: "${hex "permWrite"}", is_bold: true}
      user_execute_file: {foreground: "${hex "permExec"}", is_bold: true}
      user_execute_other: {foreground: "${hex "permExec"}", is_bold: true}
      group_read: {foreground: "${hex "permRead"}"}
      group_write: {foreground: "${hex "permWrite"}"}
      group_execute: {foreground: "${hex "permExec"}"}
      other_read: {foreground: "${hex "permRead"}"}
      other_write: {foreground: "${hex "permWrite"}"}
      other_execute: {foreground: "${hex "permExec"}"}
      special_user_file: {foreground: "${hex "special"}"}
      special_other: {foreground: "${col "surface2"}"}
      attribute: {foreground: "${hex "fgMuted"}"}

    size:
      major: {foreground: "${hex "size"}"}
      minor: {foreground: "${hex "fgMuted"}"}
      number_byte: {foreground: "${hex "size"}"}
      number_kilo: {foreground: "${hex "size"}"}
      number_mega: {foreground: "${hex "size"}"}
      number_giga: {foreground: "${hex "size"}"}
      number_huge: {foreground: "${hex "size"}"}
      unit_byte: {foreground: "${hex "fgMuted"}"}
      unit_kilo: {foreground: "${hex "fgMuted"}"}
      unit_mega: {foreground: "${hex "fgMuted"}"}
      unit_giga: {foreground: "${hex "fgMuted"}"}
      unit_huge: {foreground: "${hex "fgMuted"}"}

    users:
      user_you: {foreground: "${hex "owner"}"}
      user_root: {foreground: "${hex "root"}"}
      user_other: {foreground: "${hex "owner"}"}
      group_yours: {foreground: "${hex "group"}"}
      group_other: {foreground: "${hex "group"}"}
      group_root: {foreground: "${hex "root"}"}

    links:
      normal: {foreground: "${hex "symlink"}"}
      multi_link_file: {foreground: "${hex "symlink"}"}

    git:
      new: {foreground: "${hex "gitAdded"}"}
      modified: {foreground: "${hex "gitModified"}"}
      deleted: {foreground: "${hex "gitDeleted"}"}
      renamed: {foreground: "${hex "gitRenamed"}"}
      typechange: {foreground: "${col "yellow"}"}
      ignored: {foreground: "${hex "gitIgnored"}"}
      conflicted: {foreground: "${hex "gitConflict"}"}

    git_repo:
      branch_main: {foreground: "${hex "fgMuted"}"}
      branch_other: {foreground: "${hex "accent"}"}
      git_clean: {foreground: "${col "green"}"}
      git_dirty: {foreground: "${col "red"}"}

    security_context:
      colon: {foreground: "${hex "punct"}"}
      user: {foreground: "${hex "fgMuted"}"}
      role: {foreground: "${hex "accent"}"}
      typ: {foreground: "${col "overlay0"}"}
      range: {foreground: "${hex "accent"}"}

    file_type:
      image: {foreground: "${hex "image"}"}
      video: {foreground: "${hex "video"}"}
      music: {foreground: "${hex "audio"}"}
      lossless: {foreground: "${hex "audio"}"}
      crypto: {foreground: "${col "subtext0"}"}
      document: {foreground: "${hex "document"}"}
      compressed: {foreground: "${hex "archive"}"}
      temp: {foreground: "${col "maroon"}"}
      compiled: {foreground: "${col "blue"}"}
      source: {foreground: "${hex "source"}"}

    punctuation: {foreground: "${hex "punct"}"}
    date: {foreground: "${hex "date"}"}
    inode: {foreground: "${hex "fgMuted"}"}
    blocks: {foreground: "${col "overlay0"}"}
    header: {foreground: "${hex "fg"}"}
    octal: {foreground: "${col "blue"}"}
    flags: {foreground: "${hex "accent"}"}

    symlink_path: {foreground: "${hex "symlink"}"}
    control_char: {foreground: "${col "blue"}"}
    broken_symlink: {foreground: "${col "red"}"}
    broken_path_overlay: {foreground: "${col "overlay0"}"}
  '';

  brootThemeFile = "catppuccin-unified.hjson";
  brootSkin = ''
    skin: {
      default: ${RGB "fg"} none
      tree: ${rgb "overlay0"} none
      parent: ${RGB "fgMuted"} none
      file: ${RGB "file"} none
      directory: ${RGB "directory"} none Bold
      exe: ${RGB "executable"} none
      link: ${RGB "symlink"} none
      pruning: ${rgb "overlay0"} none Italic
      perm__: ${RGB "permNone"} none
      perm_r: ${RGB "permRead"} none
      perm_w: ${RGB "permWrite"} none
      perm_x: ${RGB "permExec"} none
      owner: ${RGB "owner"} none
      group: ${RGB "group"} none
      count: ${RGB "fgMuted"} ${rgb "surface0"}
      dates: ${RGB "date"} none
      sparse: ${rgb "subtext0"} none
      content_extract: ${rgb "blue"} none
      content_match: ${rgb "green"} none
      device_id_major: ${RGB "device"} none
      device_id_sep: ${rgb "overlay0"} none
      device_id_minor: ${RGB "device"} none

      git_branch: ${RGB "accent"} none
      git_insertions: ${RGB "gitAdded"} none
      git_deletions: ${RGB "gitDeleted"} none
      git_status_current: ${RGB "fgMuted"} none
      git_status_modified: ${RGB "gitModified"} none
      git_status_new: ${RGB "gitAdded"} none Bold
      git_status_ignored: ${RGB "gitIgnored"} none
      git_status_conflicted: ${RGB "gitConflict"} none
      git_status_other: ${rgb "red"} none

      selected_line: none ${rgb "surface0"}
      char_match: ${rgb "green"} none Bold
      file_error: ${rgb "red"} none

      flag_label: ${RGB "fgMuted"} none
      flag_value: ${RGB "accent"} none Bold

      input: ${RGB "fg"} none

      status_error: ${RGB "fg"} ${rgb "red"}
      status_job: ${RGB "accent"} ${rgb "surface1"}
      status_normal: ${RGB "fg"} ${rgb "surface0"}
      status_italic: ${RGB "accent"} ${rgb "surface0"} Italic
      status_bold: ${RGB "accent"} ${rgb "surface0"} Bold
      status_code: ${RGB "fg"} ${rgb "surface0"}
      status_ellipsis: ${RGB "fg"} ${rgb "surface1"}

      purpose_normal: ${RGB "fg"} ${rgb "surface1"}
      purpose_italic: ${RGB "accent"} ${rgb "surface1"} Italic
      purpose_bold: ${RGB "accent"} ${rgb "surface1"} Bold
      purpose_ellipsis: ${RGB "fg"} ${rgb "surface1"}

      scrollbar_track: ${rgb "surface0"} none
      scrollbar_thumb: ${rgb "overlay0"} none

      help_paragraph: ${RGB "fg"} none
      help_bold: ${RGB "accent"} none Bold
      help_italic: ${RGB "accent"} none Italic
      help_code: ${RGB "fg"} ${rgb "surface0"}
      help_headers: ${RGB "accent"} none
      help_table_border: ${rgb "overlay0"} none

      preview_title: ${RGB "fgMuted"} ${rgb "mantle"}
      preview: ${RGB "fg"} ${rgb "mantle"}
      preview_separator: ${RGB "accent"} none
      preview_line_number: ${RGB "fgMuted"} ${rgb "surface0"}
      preview_match: none ${rgb "green"}

      staging_area_title: ${RGB "fgMuted"} ${rgb "mantle"}
      mode_command_mark: ${rgb "base"} ${RGB "accent"} Bold

      hex_null: ${rgb "overlay0"} none
      hex_ascii_graphic: ${RGB "fgMuted"} none
      hex_ascii_whitespace: ${rgb "yellow"} none
      hex_ascii_other: ${rgb "peach"} none
      hex_non_ascii: ${rgb "red"} none

      good_to_bad_0: ${rgb "green"}
      good_to_bad_1: ${rgb "green"}
      good_to_bad_2: ${rgb "green"}
      good_to_bad_3: ${rgb "green"}
      good_to_bad_4: ${rgb "yellow"}
      good_to_bad_5: ${rgb "yellow"}
      good_to_bad_6: ${rgb "peach"}
      good_to_bad_7: ${rgb "peach"}
      good_to_bad_8: ${rgb "red"}
      good_to_bad_9: ${rgb "red"}

    }
  '';

  yaziTheme = ''
    [app]
    overall = { bg = "${col "base"}" }

    [mgr]
    cwd = { fg = "${hex "directory"}" }

    find_keyword  = { fg = "${col "yellow"}", italic = true }
    find_position = { fg = "${col "pink"}", bg = "reset", italic = true }

    marker_copied   = { fg = "${col "green"}", bg = "${col "green"}" }
    marker_cut      = { fg = "${col "red"}", bg = "${col "red"}" }
    marker_marked   = { fg = "${col "teal"}", bg = "${col "teal"}" }
    marker_selected = { fg = "${hex "accent"}", bg = "${hex "accent"}" }

    count_copied   = { fg = "${col "base"}", bg = "${col "green"}" }
    count_cut      = { fg = "${col "base"}", bg = "${col "red"}" }
    count_selected = { fg = "${col "base"}", bg = "${hex "accent"}" }

    border_symbol = "│"
    border_style  = { fg = "${col "overlay1"}" }

    syntect_theme = "~/.config/yazi/Catppuccin-${flavor}.tmTheme"

    [tabs]
    active   = { fg = "${col "base"}", bg = "${col "text"}", bold = true }
    inactive = { fg = "${col "text"}", bg = "${col "surface1"}" }

    [mode]
    normal_main = { fg = "${col "base"}", bg = "${hex "accent"}", bold = true }
    normal_alt  = { fg = "${hex "accent"}", bg = "${col "surface0"}" }

    select_main = { fg = "${col "base"}", bg = "${col "green"}", bold = true }
    select_alt  = { fg = "${col "green"}", bg = "${col "surface0"}" }

    unset_main  = { fg = "${col "base"}", bg = "${col "flamingo"}", bold = true }
    unset_alt   = { fg = "${col "flamingo"}", bg = "${col "surface0"}" }

    [indicator]
    parent  = { fg = "${col "base"}", bg = "${col "text"}" }
    current = { fg = "${col "base"}", bg = "${hex "accent"}" }
    preview = { fg = "${col "base"}", bg = "${col "text"}" }

    [status]
    sep_left  = { open = "", close = "" }
    sep_right = { open = "", close = "" }

    progress_label  = { fg = "${col "text"}", bold = true }
    progress_normal = { fg = "${col "green"}", bg = "${col "surface1"}" }
    progress_error  = { fg = "${col "yellow"}", bg = "${col "red"}" }

    perm_type  = { fg = "${hex "permType"}" }
    perm_read  = { fg = "${hex "permRead"}" }
    perm_write = { fg = "${hex "permWrite"}" }
    perm_exec  = { fg = "${hex "permExec"}" }
    perm_sep   = { fg = "${col "overlay0"}" }

    [input]
    border   = { fg = "${hex "accent"}" }
    title    = {}
    value    = {}
    selected = { reversed = true }

    [pick]
    border   = { fg = "${hex "accent"}" }
    active   = { fg = "${col "pink"}" }
    inactive = {}

    [confirm]
    border  = { fg = "${hex "accent"}" }
    title   = { fg = "${hex "accent"}" }
    body    = {}
    list    = {}
    btn_yes = { reversed = true }
    btn_no  = {}

    [cmp]
    border = { fg = "${hex "accent"}" }

    [tasks]
    border  = { fg = "${hex "accent"}" }
    title   = {}
    hovered = { fg = "${col "pink"}", bold = true }

    [which]
    mask            = { bg = "${col "surface0"}" }
    cand            = { fg = "${col "teal"}" }
    rest            = { fg = "${col "overlay2"}" }
    desc            = { fg = "${col "pink"}" }
    separator       = "  "
    separator_style = { fg = "${col "surface2"}" }

    [help]
    on      = { fg = "${col "teal"}" }
    run     = { fg = "${col "pink"}" }
    desc    = { fg = "${col "overlay2"}" }
    hovered = { bg = "${col "surface2"}", bold = true }
    footer  = { fg = "${col "text"}", bg = "${col "surface1"}" }

    [notify]
    title_info  = { fg = "${col "teal"}" }
    title_warn  = { fg = "${col "yellow"}" }
    title_error = { fg = "${col "red"}" }

    [filetype]
    rules = [
    	{ mime = "image/*", fg = "${hex "image"}" },
    	{ mime = "video/*", fg = "${hex "video"}" },
    	{ mime = "audio/*", fg = "${hex "audio"}" },

    	{ mime = "application/*zip", fg = "${hex "archive"}" },
    	{ mime = "application/x-{tar,bzip*,7z-compressed,xz,rar}", fg = "${hex "archive"}" },

    	{ mime = "application/{pdf,doc,rtf}", fg = "${hex "document"}" },

    	{ mime = "vfs/{absent,stale}", fg = "${col "surface1"}" },

    	{ url = "*", is = "orphan", bg = "${col "red"}" },
    	{ url = "*", is = "exec"  , fg = "${hex "executable"}" },

    	{ url = "*", is = "dummy", bg = "${col "red"}" },
    	{ url = "*/", is = "dummy", bg = "${col "red"}" },

    	{ url = "*/", fg = "${hex "directory"}" }
    ]

    [spot]
    border   = { fg = "${hex "accent"}" }
    title    = { fg = "${hex "accent"}" }
    tbl_cell = { fg = "${hex "accent"}", reversed = true }
    tbl_col  = { bold = true }
  '';
in
{
  config = lib.mkIf cat.enable (
    lib.mkMerge [
      # Stop the catppuccin module from writing its per-tool themes; we own them.
      {
        catppuccin.eza.enable = false;
        catppuccin.broot.enable = false;
        catppuccin.yazi.enable = false;
      }

      (lib.mkIf config.programs.eza.enable {
        xdg.configFile."eza/theme.yml".text = ezaTheme;
      })

      (lib.mkIf config.programs.broot.enable {
        xdg.configFile."broot/skins/${brootThemeFile}".text = brootSkin;
        programs.broot.settings.ext_colors = extColors;
        programs.broot.settings.imports = [
          {
            file = "skins/${brootThemeFile}";
            luma = "light";
          }
          {
            file = "skins/${brootThemeFile}";
            luma = [
              "dark"
              "unknown"
            ];
          }
        ];
      })

      (lib.mkIf config.programs.yazi.enable {
        xdg.configFile."yazi/theme.toml".text = yaziTheme;
        # Keep the bat-based syntax-highlight theme used by the file preview.
        xdg.configFile."yazi/Catppuccin-${flavor}.tmTheme".source =
          "${sources.bat}/Catppuccin ${lib.toSentenceCase flavor}.tmTheme";
      })
    ]
  );
}
