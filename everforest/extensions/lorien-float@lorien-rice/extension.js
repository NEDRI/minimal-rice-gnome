// Super+H: the focused window goes onto the "stage" (the middle of the work area, `gap` px from every edge);
// pressed on a window already there, it becomes a smaller window in the middle (60% x 70%). New normal windows open
// the same way, so every app starts on the same floating "stage". A port of the rice's KWin lorien-center.
import Meta from 'gi://Meta';
import Shell from 'gi://Shell';
import GLib from 'gi://GLib';
import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import {Extension} from 'resource:///org/gnome/shell/extensions/extension.js';

const ISLE = 'isle@zickrian.github.io';

// allows_resize()/allows_move() are false for a maximized or edge-tiled window, so they can't decide this:
// the `resizeable` property says whether the app lets its window change size at all.
function floatable(win) {
    if (!win || win.get_window_type() !== Meta.WindowType.NORMAL || win.get_transient_for() || win.is_fullscreen())
        return false;
    if ('resizeable' in win)
        return win.resizeable;
    return isMaximized(win) || (win.allows_resize() && win.allows_move());
}

function unmaximize(win) {
    try {
        win.unmaximize(Meta.MaximizeFlags.BOTH);   // GNOME <= 48
    } catch (e) {
        win.unmaximize();                          // GNOME 49+
    }
}

function maximize(win) {
    try {
        win.maximize(Meta.MaximizeFlags.BOTH);
    } catch (e) {
        win.maximize();
    }
}

function isMaximized(win) {
    if (typeof win.is_maximized === 'function')
        return win.is_maximized();
    return win.get_maximized() === Meta.MaximizeFlags.BOTH;
}

export default class LorienFloat extends Extension {
    enable() {
        this._settings = this.getSettings();
        Main.wm.addKeybinding('float-window', this._settings, Meta.KeyBindingFlags.NONE,
            Shell.ActionMode.NORMAL, () => this._toggle(global.display.get_focus_window()));
        this._createdId = global.display.connect('window-created', (_d, win) => this._onCreated(win));
    }

    disable() {
        Main.wm.removeKeybinding('float-window');
        global.display.disconnect(this._createdId);
        this._settings = null;
    }

    // Isle draws its island at the top of every display ('all') or of the active one ('active'). A display
    // without GNOME's top bar has its work area from the very top, so the stage would slide under the island:
    // there it starts one bar height lower, the same as on the display with the bar.
    _islandInset(win, a) {
        if (!global.settings.get_strv('enabled-extensions').includes(ISLE))
            return 0;
        try {
            const where = Main.extensionManager.lookup(ISLE)?.stateObj?.getSettings()?.get_string('island-monitor');
            if (where === 'primary' && win.get_monitor() !== Main.layoutManager.primaryIndex)
                return 0;
        } catch (e) {
            // Isle's settings unreadable: keep the island clear anyway
        }
        const m = global.display.get_monitor_geometry(win.get_monitor());
        return a.y <= m.y ? Main.panel.height : 0;
    }

    // The monitor's work area, minus the island's strip where the top bar does not reserve it.
    _workArea(win) {
        const a = win.get_work_area_current_monitor();
        const top = this._islandInset(win, a);
        return {x: a.x, y: a.y + top, width: a.width, height: a.height - top};
    }

    _stageRect(win) {
        const gap = this._settings.get_int('gap');
        const a = this._workArea(win);
        return {x: a.x + gap, y: a.y + gap, width: a.width - 2 * gap, height: a.height - 2 * gap};
    }

    _place(win, r = this._stageRect(win)) {
        if (isMaximized(win))
            unmaximize(win);
        win.move_resize_frame(true, r.x, r.y, r.width, r.height);
    }

    // Super+H: on the stage (centred, gaps on every side) <-> a smaller window in the middle (60% x 70%).
    // A maximized window, or one anywhere else, goes onto the stage first.
    _toggle(win) {
        if (!floatable(win))
            return;
        const stage = this._stageRect(win);
        const r = win.get_frame_rect();
        const near = (a, b) => Math.abs(a - b) <= 24;
        const onStage = !isMaximized(win) && near(r.x, stage.x) && near(r.y, stage.y)
            && near(r.width, stage.width) && near(r.height, stage.height);
        if (!onStage) {
            this._place(win, stage);
            return;
        }
        const a = this._workArea(win);
        const w = Math.round(a.width * 0.6), h = Math.round(a.height * 0.7);
        this._place(win, {x: a.x + Math.round((a.width - w) / 2), y: a.y + Math.round((a.height - h) / 2), width: w, height: h});
    }

    _onCreated(win) {
        if (!this._settings.get_boolean('float-new-windows'))
            return;
        // wait for the first frame: before it, mutter still sets the app's own size and place
        const actor = win.get_compositor_private();
        if (!actor)
            return;
        const id = actor.connect('first-frame', () => {
            actor.disconnect(id);
            GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
                if (floatable(win))
                    this._place(win);
                return GLib.SOURCE_REMOVE;
            });
        });
    }
}
