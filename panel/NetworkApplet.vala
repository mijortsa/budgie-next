/*
 * NetworkApplet.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

public class NetworkApplet : Gtk.EventBox
{
    protected int icon_size = 24;
    Gtk.Image? image;

    public NetworkApplet()
    {
        image = new Gtk.Image.from_icon_name("network-wired-disconnected-symbolic", Gtk.IconSize.INVALID);
        image.pixel_size = icon_size;
        add(image);
    }

} // End class
