"""Home Manager integration for MusicBrainz Picard.

Loaded through a `.pth` file on NIX_PYTHONPATH before Picard starts. Options
listed in the JSON file at $HM_PICARD_MANAGED_SETTINGS are overlaid on top of
Picard.ini in memory:

- reads of a managed option always return the Nix value (this also wins over
  option profiles),
- writes to a managed option are dropped,
- widgets bound to a managed option in the Options dialog and its entry in the
  quick settings menu are disabled.

Picard.ini itself is never touched, so removing an option from the Nix config
brings back whatever value the user had before.
"""

import importlib.abc
import json
import os
import sys

_MANAGED: dict = {}
_TOOLTIP = "This option is managed by Home Manager."


def _log():
    from picard import log

    return log


def _patch_config(mod):
    cls = mod.SettingConfigSection
    orig_getitem = cls.__getitem__
    orig_setitem = cls.__setitem__

    def __getitem__(self, name):
        if name in _MANAGED:
            opt = mod.Option.get(self.section_name, name)
            if opt is not None:
                try:
                    return opt.convert(_MANAGED[name])
                except Exception as e:
                    _log().error("Home Manager: invalid value for setting/%s: %s", name, e)
        return orig_getitem(self, name)

    def __setitem__(self, name, value):
        if name in _MANAGED:
            _log().debug("Home Manager: ignoring write to managed setting/%s", name)
            return
        orig_setitem(self, name, value)

    cls.__getitem__ = __getitem__
    cls.__setitem__ = __setitem__

    orig_setup_config = mod.setup_config

    def setup_config(*args, **kwargs):
        orig_setup_config(*args, **kwargs)
        # All core options are registered by init_options() before this runs.
        for name in _MANAGED:
            if not mod.Option.exists('setting', name):
                _log().warning("Home Manager: unknown setting %r in programs.picard.settings", name)

    mod.setup_config = setup_config


def _patch_options_dialog(mod):
    from picard.profile import profile_groups_group_from_page

    cls = mod.OptionsDialog
    orig = cls._highlight_page_options

    # Called on dialog show, on every page switch and after profile changes,
    # each time after the widget tooltips have been reset.
    def _highlight_page_options(self, page, load_settings=False):
        orig(self, page, load_settings=load_settings)
        group = profile_groups_group_from_page(page)
        if not group:
            return
        for desc in group.get('settings', ()):
            if desc.section != 'setting' or desc.name not in _MANAGED:
                continue
            for objname in desc.highlights:
                obj = getattr(getattr(page, 'ui', None), objname, None)
                if obj is None:
                    obj = getattr(page, objname, None)
                if obj is None or not hasattr(obj, 'setEnabled'):
                    continue
                obj.setEnabled(False)
                tooltip = obj.toolTip()
                if _TOOLTIP not in tooltip:
                    obj.setToolTip(f"{tooltip}\n{_TOOLTIP}" if tooltip else _TOOLTIP)

    cls._highlight_page_options = _highlight_page_options


def _patch_main_window(mod):
    # The quick settings menu only knows the option titles when it builds its
    # entries, so catch them at creation time.
    orig = mod.create_checkable_menu_item

    def create_checkable_menu_item(menu_bar, menu, title, checked):
        action = orig(menu_bar, menu, title, checked)
        titles = (mod.get_option_title(name) for name in _MANAGED)
        if title in {mod._(t) for t in titles if t}:
            action.setEnabled(False)
            widget = action.defaultWidget() if hasattr(action, 'defaultWidget') else None
            (widget or action).setToolTip(_TOOLTIP)
        return action

    mod.create_checkable_menu_item = create_checkable_menu_item


_HOOKS = {
    'picard.config': _patch_config,
    'picard.ui.options.dialog': _patch_options_dialog,
    'picard.ui.mainwindow': _patch_main_window,
}


class _PostImportFinder(importlib.abc.MetaPathFinder):
    """Runs a hook right after one of the modules in _HOOKS has executed."""

    def find_spec(self, name, path, target=None):
        hook = _HOOKS.pop(name, None)
        if hook is None:
            return None
        for finder in sys.meta_path:
            if finder is self or not hasattr(finder, 'find_spec'):
                continue
            spec = finder.find_spec(name, path, target)
            if spec is not None:
                break
        else:
            return None
        exec_module = spec.loader.exec_module

        def exec_and_patch(module):
            exec_module(module)
            try:
                hook(module)
            except Exception as e:
                print(f"hm_picard: failed to patch {name}: {e!r}", file=sys.stderr)

        spec.loader.exec_module = exec_and_patch
        return spec


def _install():
    path = os.environ.get('HM_PICARD_MANAGED_SETTINGS')
    if not path:
        return
    try:
        with open(path, encoding='utf-8') as f:
            _MANAGED.update(json.load(f).get('settings', {}))
    except (OSError, ValueError) as e:
        print(f"hm_picard: cannot read {path}: {e}", file=sys.stderr)
        return
    if _MANAGED:
        sys.meta_path.insert(0, _PostImportFinder())


_install()
