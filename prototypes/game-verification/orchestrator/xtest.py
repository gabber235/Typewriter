"""Spike J path X: window system input through XTest on the client's own Xvfb display (Linux only).

The orchestrator is the 'person': it sends X key, button and motion events with XTest, and waits in
client ticks by asking the client how many ticks have run. Never used on a desktop display.
"""
import math, time

from Xlib import X, XK, display as xdisplay
from Xlib.ext import xtest

KEYS = {"T": "t", "SLASH": "slash", "ENTER": "Return", "ESC": "Escape", "F": "f", "E": "e", "W": "w", "SPACE": "space", "SHIFT": "Shift_L"}
CHAR = {" ": "space", "/": "slash"}


class XTest:
    def __init__(self, session):
        self.s = session
        self.C = session.C
        name = session.display.name
        assert name.startswith(":") and int(name[1:]) >= 90, "XTest only on the spike's own Xvfb display"
        self.d = xdisplay.Display(name)
        self.root = self.d.screen().root
        self.win = self.find_window()
        self.win.set_input_focus(X.RevertToParent, X.CurrentTime)
        self.d.sync()
        geo = self.win.get_geometry()
        pos = self.win.translate_coords(self.root, 0, 0)
        self.origin = (-pos.x, -pos.y)
        self.size = (geo.width, geo.height)
        self.cursor = (self.origin[0] + geo.width // 2, self.origin[1] + geo.height // 2)
        xtest.fake_input(self.d, X.MotionNotify, x=self.cursor[0], y=self.cursor[1])
        self.d.sync()

    def find_window(self):
        best = None
        for w in self.root.query_tree().children:
            try:
                attrs = w.get_attributes()
                geo = w.get_geometry()
            except Exception:
                continue
            if attrs.map_state != X.IsViewable:
                continue
            if best is None or geo.width * geo.height > best[0]:
                best = (geo.width * geo.height, w)
        assert best, "no client window on the Xvfb display"
        return best[1]

    # ---- low level ----

    def code(self, name):
        return self.d.keysym_to_keycode(XK.string_to_keysym(name))

    def key(self, name, down):
        xtest.fake_input(self.d, X.KeyPress if down else X.KeyRelease, self.code(name))
        self.d.sync()

    def press(self, name):
        self.key(name, True)
        self.wait(1)
        self.key(name, False)

    def type(self, text):
        for ch in text:
            name = CHAR.get(ch, ch)
            self.key(name, True)
            self.key(name, False)

    def button(self, b, down):
        xtest.fake_input(self.d, X.ButtonPress if down else X.ButtonRelease, b)
        self.d.sync()

    def motion_to(self, x, y):
        self.cursor = (int(round(x)), int(round(y)))
        xtest.fake_input(self.d, X.MotionNotify, x=self.cursor[0], y=self.cursor[1])
        self.d.sync()

    def ticks(self):
        return self.C("in.ticks")["ticks"]

    def wait(self, n):
        target = self.ticks() + n
        while self.ticks() < target:
            time.sleep(0.0005)

    def until(self, cond, max_ticks, **q):
        start = self.ticks()
        while True:
            st = self.C("in.state", **q)
            if cond(st):
                return st, False
            if st["ticks"] - start >= max_ticks:
                return st, True
            time.sleep(0.0005)

    def center(self):
        """Pointer back to the middle of the window: without a real grab nothing warps it, so it drifts off."""
        self.motion_to(self.origin[0] + self.size[0] // 2, self.origin[1] + self.size[1] // 2)

    def grab(self):
        """A person's first click into the window takes the mouse (real grab only); done before any measured input."""
        if not self.C("in.state")["grabbed"]:
            self.center()
            self.button(1, True)
            self.button(1, False)
            self.wait(3)
        return self.C("in.state")["grabbed"]

    def aim(self, at, notes):
        st = self.C("in.state")
        ex, ey, ez = st["eye"]
        dx, dy, dz = at[0] - ex, at[1] - ey, at[2] - ez
        yaw = math.degrees(math.atan2(-dx, dz))
        pitch = -math.degrees(math.atan2(dy, math.hypot(dx, dz)))
        dyaw = (yaw - st["yaw"] + 180) % 360 - 180
        dpitch = pitch - st["pitch"]
        per_pixel = st["perPixel"]
        # A small nudge first: the first motion after a grab only sets the cursor.
        self.motion_to(self.cursor[0] + 1, self.cursor[1])
        self.wait(1)
        self.motion_to(self.cursor[0] + dyaw / per_pixel - 1, self.cursor[1] + dpitch / per_pixel)
        self.wait(2)
        st = self.C("in.state")
        notes.update(yaw=round(st["yaw"], 2), pitch=round(st["pitch"], 2), aimHit=st.get("hit"))

    # ---- ops, the same scripts as the client side paths ----

    def run(self, op, q, mark):
        if op != "inv":
            self.center()
            self.wait(1)
        t0 = self.ticks()
        notes = {}
        timed_out = False
        if op in ("chat", "cmd", "suggest"):
            self.press("t" if op == "chat" else "slash")
            _, to = self.until(lambda st: st["screen"] == "ChatScreen", 10)
            timed_out |= to
            self.type(q["text"])
            if op == "suggest":
                st, to = self.until(lambda st: q["want"] in st.get("suggestions", ""), int(q.get("max", 40)))
                timed_out |= to
                notes["suggestions"] = st.get("suggestions", "")
                drawn = self.s.C("drawn", frames=3)
                notes["drawnHasWant"] = q["want"] in json_text(drawn)
                self.press("Escape")
            else:
                self.press("Return")
            self.wait(1)
            notes["screenAfter"] = self.C("in.state")["screen"]
        elif op == "break":
            pos = f'{q["x"]},{q["y"]},{q["z"]}'
            self.aim((q["x"] + 0.5, q["y"] + 0.5, q["z"] + 0.5), notes)
            self.button(1, True)
            st, to = self.until(lambda st: st.get("block") == "minecraft:air", int(q["max"]), block=pos)
            timed_out |= to
            notes["airAfter"] = st["ticks"] - t0
            self.wait(1)
            self.button(1, False)
            self.wait(4)
            notes["blockAfter"] = self.C("in.state", block=pos)["block"]
        elif op == "use":
            self.button(3, True)
            self.wait(int(q["hold"]))
            notes["scoping"] = self.C("in.state")["scoping"]
            self.button(3, False)
            self.wait(1)
        elif op == "swap":
            self.press("f")
            self.wait(2)
            notes["offhand"] = self.C("in.state")["off"]
        elif op == "scroll":
            b = 5 if int(q.get("dir", -1)) < 0 else 4
            self.button(b, True)
            self.button(b, False)
            self.wait(2)
            notes["slot"] = self.C("in.state")["slot"]
        elif op == "num":
            self.press(str(q["n"]))
            self.wait(2)
            notes["slot"] = self.C("in.state")["slot"]
        elif op in ("sneak", "jump", "fly"):
            name = "Shift_L" if op == "sneak" else "space"
            y0 = self.C("in.state")["pos"][1]
            self.key(name, True)
            self.wait(int(q["hold"]))
            self.key(name, False)
            top = 0
            start = self.ticks()
            while True:
                st = self.C("in.state")
                top = max(top, st["pos"][1] - y0)
                if op == "fly" or st["onGround"] or st["ticks"] - start > 20:
                    break
                time.sleep(0.0005)
            notes["rise"] = round(top, 3)
            notes["sneaking"] = st.get("sneaking")
        elif op in ("attack", "interact"):
            self.aim((q["x"], q["y"], q["z"]), notes)
            st = self.C("in.state")
            notes["hit"], notes["hitEntity"] = st.get("hit", "").split(":")[0], st.get("hitEntity")
            b = 1 if op == "attack" else 3
            self.button(b, True)
            self.wait(1)
            self.button(b, False)
            self.wait(1)
        elif op == "inv":
            self.press("e")
            _, to = self.until(lambda st: st["screen"] == "InventoryScreen", 10)
            timed_out |= to
            sp = self.C("in.state", slot=q["slot"])["slotPos"]
            self.motion_to(self.origin[0] + sp[0], self.origin[1] + sp[1])
            self.wait(1)
            self.button(1, True)
            self.wait(1)
            self.button(1, False)
            self.wait(1)
            notes["carried"] = self.C("in.state")["carried"]
            self.press("e")
            self.wait(2)
            st = self.C("in.state")
            notes["screenAfter"] = st["screen"]
            # Back to the middle so the next aim starts where a grabbed cursor would be.
            self.motion_to(self.origin[0] + self.size[0] // 2, self.origin[1] + self.size[1] // 2)
        elif op == "move":
            tx, tz = float(q.get("x", 0.5)), float(q.get("z", 4.5))
            st = self.C("in.state")
            self.aim((tx, st["eye"][1], tz), notes)
            self.key("w", True)
            _, to = self.until(lambda st: math.hypot(st["pos"][0] - tx, st["pos"][2] - tz) < 0.3, int(q.get("max", 80)))
            timed_out |= to
            self.key("w", False)
            self.wait(6)
            p = self.C("in.state")["pos"]
            notes["pos"] = f"{p[0]:.2f},{p[1]:.2f},{p[2]:.2f}"
        else:
            raise ValueError(op)
        r = self.C("in.mark", mark=mark, settle=2)
        r.update(notes)
        r["ticks"] = self.ticks() - t0
        r["ok"] = not timed_out
        return r


def json_text(o):
    import json
    return json.dumps(o)
