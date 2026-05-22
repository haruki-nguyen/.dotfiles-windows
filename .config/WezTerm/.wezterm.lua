-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This will hold the configuration.
-- Using config_builder() is recommended for better error messages
local config = wezterm.config_builder()

-- =====================================================================
-- 1. APPEARANCE & WINDOWS 11 INTEGRATION
-- =====================================================================

-- Emulate Windows Terminal Font (Requires Cascadia Code to be installed)
config.font = wezterm.font('JetBrains Mono', { weight = 'Regular' })
config.font_size = 13.0

-- A clean, high-contrast dark theme similar to Windows Terminal's default
-- config.color_scheme = 'Campbell' 

-- Windows 11 Native feel: Use Mica background material and remove old titlebars
config.window_decorations = "RESIZE" 
-- config.win32_system_backdrop = 'Mica'
config.window_background_opacity = 1 -- Slight transparency

-- Modern Tab Bar Styling
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = true
config.show_tab_index_in_tab_bar = true

-- Padding around the terminal edge
config.window_padding = {
  left = 8,
  right = 8,
  top = 8,
  bottom = 8,
}

-- =====================================================================
-- 2. PROGRAMMER QUALITY-OF-LIFE FEATURES
-- =====================================================================

-- Massive scrollback buffer (Standard for reading long build logs)
config.scrollback_lines = 10000

-- Automatically copy text to the clipboard when you select it with the mouse
config.selection_word_boundary = " \t\n{}[]()\"'`"

-- Default to PowerShell on Windows (Comment out to use standard cmd.exe)
config.default_prog = { 'pwsh.exe', '-NoLogo' }

-- Update the terminal quickly for smoother scrolling/animations
config.animation_fps = 60
config.max_fps = 120

-- =====================================================================
-- 3. KEYBINDINGS (MIMICKING WINDOWS TERMINAL)
-- =====================================================================
local act = wezterm.action

-- Disable WezTerm's default keys to strictly enforce our custom ones
config.disable_default_key_bindings = false

config.keys = {
  -- Copy & Paste
  { key = 'C', mods = 'CTRL|SHIFT', action = act.CopyTo 'Clipboard' },
  { key = 'V', mods = 'CTRL|SHIFT', action = act.PasteFrom 'Clipboard' },

  -- Tab Management (Ctrl+Shift+T / Ctrl+Shift+W)
  { key = 'T', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'W', mods = 'CTRL|SHIFT', action = act.CloseCurrentTab { confirm = true } },
  
  -- Navigate Tabs (Ctrl+Tab / Ctrl+Shift+Tab)
  { key = 'Tab', mods = 'CTRL', action = act.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },

  -- Search (Ctrl+Shift+F)
  { key = 'F', mods = 'CTRL|SHIFT', action = act.Search 'CurrentSelectionOrEmptyString' },

  -- Command Palette (Ctrl+Shift+P)
  { key = 'P', mods = 'CTRL|SHIFT', action = act.ActivateCommandPalette },

  -- ===================================================================
  -- MULTIPLEXING: SPLIT PANES (Alt+Shift+Minus / Alt+Shift+Plus)
  -- ===================================================================
  -- Split horizontally (Side-by-side)
  { 
    key = '+', 
    mods = 'ALT|SHIFT', 
    action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } 
  },
  -- Split vertically (Top-and-bottom)
  { 
    key = '_', 
    mods = 'ALT|SHIFT', 
    action = act.SplitVertical { domain = 'CurrentPaneDomain' } 
  },
  
  -- Move between split panes (Alt + Arrows)
  { key = 'LeftArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Left' },
  { key = 'RightArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Right' },
  { key = 'UpArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Up' },
  { key = 'DownArrow', mods = 'ALT', action = act.ActivatePaneDirection 'Down' },
  
  -- Close current pane
  { key = 'W', mods = 'CTRL|ALT', action = act.CloseCurrentPane { confirm = true } },
}

-- Finally, return the configuration to WezTerm
return config