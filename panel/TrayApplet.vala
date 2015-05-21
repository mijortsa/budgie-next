/*
 * TrayApplet.vala
 * 
 * Copyright 2014 Ikey Doherty <ikey.doherty@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class TrayApplet : Gtk.Box
{
    protected Na.Tray? tray;
    protected int icon_size = 24;
    Gtk.EventBox box;

    public TrayApplet()
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        margin = 1;
        box = new Gtk.EventBox();
        pack_start(box, true, true, 0);
        box.vexpand = false;
        valign = Gtk.Align.CENTER;

        integrate_tray();
    }

    protected void integrate_tray()
    {
        tray = new Na.Tray.for_screen(get_screen(), Gtk.Orientation.HORIZONTAL);
        tray.set_icon_size(icon_size);
        box.add(tray);
        show_all();
        tray.set_icon_size(icon_size);
    }

    public override void get_preferred_height(out int min, out int nat)
    {
        min = icon_size;
        nat = icon_size;
    }

    public override void get_preferred_height_for_width(int h, out int min, out int nat)
    {
        min = icon_size;
        nat = icon_size;
    }
} // End class
