/*
 * BudgiePanel.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

namespace Budgie
{

public class Slat : Gtk.Window
{

    Gdk.Rectangle scr;
    int intended_height = 42;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    public Slat()
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }

        // TODO: Track
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out orig_scr);

        /* Smaller.. */
        small_scr = orig_scr;
        small_scr.height = intended_height;

        scr = small_scr;

        realize();
        // Revisit to account for multiple monitors..
        move(0, 0);
        show_all();
        //present();
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }
    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = scr.width;
        n = scr.width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = scr.height;
        n = scr.height;
    }
}

} // End namespace

public static void main(string[] args)
{
    Gtk.init(ref args);
    var w = new Budgie.Slat();
    Gtk.main();
    w = null;
}
