#!/usr/bin/env python3
"""Drive a running X application with real synthetic input, and capture frames.

Uses the X11 XTEST extension - the same mechanism xdotool wraps - so the target
application cannot tell these events from a physical keyboard. This is what
makes it possible to PLAY a build rather than only watch an autopilot drive it.

  python3 tools/play.py --godot /path/to/godot --project . --script sequence.txt

A sequence file is one action per line:
  wait 2.5          -- seconds
  hold w 1.2        -- press a key, hold it, release
  tap space
  shot name         -- capture a PNG
"""
import argparse, os, subprocess, sys, time

from Xlib import display, X, XK
from Xlib.ext import xtest
from PIL import Image


class Screen:
    def __init__(self, disp_name):
        self.disp = display.Display(disp_name)
        self.root = self.disp.screen().root
        geom = self.root.get_geometry()
        self.w, self.h = geom.width, geom.height

    def key(self, name):
        sym = XK.string_to_keysym(name)
        if sym == 0:
            raise SystemExit("unknown key: %s" % name)
        return self.disp.keysym_to_keycode(sym)

    def hold(self, name, seconds):
        kc = self.key(name)
        xtest.fake_input(self.disp, X.KeyPress, kc)
        self.disp.sync()
        time.sleep(seconds)
        xtest.fake_input(self.disp, X.KeyRelease, kc)
        self.disp.sync()

    def tap(self, name):
        self.hold(name, 0.06)

    def shot(self, path):
        raw = self.root.get_image(0, 0, self.w, self.h, X.ZPixmap, 0xFFFFFFFF)
        img = Image.frombytes("RGB", (self.w, self.h), raw.data, "raw", "BGRX")
        img.save(path)
        return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--godot", required=True)
    ap.add_argument("--project", default=".")
    ap.add_argument("--display", default=":99")
    ap.add_argument("--res", default="1280x720")
    ap.add_argument("--out", default="/home/user/brickstorm_shots/play")
    ap.add_argument("--script", required=True)
    ap.add_argument("--boot", type=float, default=9.0)
    ap.add_argument("--extra", default="")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)

    w, h = a.res.split("x")
    xvfb = subprocess.Popen(["Xvfb", a.display, "-screen", "0", "%sx%sx24" % (w, h)],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    time.sleep(2.0)

    env = dict(os.environ, DISPLAY=a.display)
    cmd = [a.godot, "--path", a.project, "--rendering-driver", "opengl3",
           "--resolution", a.res]
    if a.extra:
        cmd += ["--"] + a.extra.split()
    log = open(os.path.join(a.out, "game.log"), "w")
    game = subprocess.Popen(cmd, env=env, stdout=log, stderr=subprocess.STDOUT)
    time.sleep(a.boot)

    scr = Screen(a.display)
    try:
        for line in open(a.script):
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            parts = line.split()
            op = parts[0]
            if op == "wait":
                time.sleep(float(parts[1]))
            elif op == "hold":
                scr.hold(parts[1], float(parts[2]))
            elif op == "tap":
                scr.tap(parts[1])
            elif op == "shot":
                p = scr.shot(os.path.join(a.out, parts[1] + ".png"))
                print("shot %s" % p, flush=True)
            else:
                raise SystemExit("unknown op: %s" % op)
    finally:
        game.terminate()
        time.sleep(0.6)
        game.kill()
        xvfb.terminate()
    print("PLAY DONE", flush=True)


if __name__ == "__main__":
    main()
