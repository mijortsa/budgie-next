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

class ConnectionItem : Gtk.Box
{
    public unowned NM.Device? device;
    unowned NM.Connection? connection;

    public ConnectionItem(NM.Device? device, NM.Connection? connection)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.device = device;
        this.connection = connection;

        var label = new Gtk.Label(this.connection.get_id());
        pack_start(label, false, false, 0);

        //get_style_context().add_class("menuitem");

        var btn = new Gtk.Switch();
        pack_end(btn, false, false, 0);
        if (device.get_active_connection() != null && device.get_active_connection().get_connection() == connection.get_path()) {
            btn.set_active(true);
        } else {
            btn.set_active(false);
        }
    }
}

public class NetworkApplet : Gtk.EventBox
{
    protected int icon_size = 24;
    Gtk.Image? image;
    NM.Client? client = null;
    NM.RemoteSettings? settings = null;
    Gtk.Popover popover;
    Gtk.ListBox content;

    public NetworkApplet(Budgie.PopoverManager? manager)
    {
        image = new Gtk.Image.from_icon_name("network-wired-disconnected-symbolic", Gtk.IconSize.INVALID);
        image.pixel_size = icon_size;
        add(image);

        try {
            client = new NM.Client();
            settings = new NM.RemoteSettings(null);
        } catch (Error e) {
            warning("Networking unavailable at this time");
            no_show_all = true;
            image.hide();
        }

        popover = new Gtk.Popover(this);
        this.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.show_all();
            }
            return Gdk.EVENT_STOP;
        });
        manager.register_popover(this, popover);

        content = new Gtk.ListBox();
        //content.get_style_context().add_class("menu");
        content.set_header_func(do_header);
        popover.add(content);
        content.vexpand = true;
        content.hexpand = true;
        content.halign = Gtk.Align.FILL;
        content.valign = Gtk.Align.START;
        popover.set_size_request(100, 100);
        init_applet();
        init_devices();
    }

    void do_header(Gtk.ListBoxRow? a, Gtk.ListBoxRow? b)
    {
        NM.Device? l = null;
        NM.Device? r = null;
        if (a != null) {
            l = (a.get_child() as ConnectionItem).device;
        }
        if (b != null) {
            r = (b.get_child() as ConnectionItem).device;
        }
        if (a == null || b == null || l != r) {
            var header = new Gtk.Label("<big>%s</big>".printf(l.product));
            header.set_use_markup(true);
            header.get_style_context().add_class("dim-label");
            a.set_header(header);
        } else {
            a.set_header(null);
        }

    }

    static string dev_desc(NM.Device? dev)
    {
        return dev.product;
        return "%s %s".printf(dev.get_vendor(), dev.get_product());
    }

    void init_devices()
    {
        if (client == null) {
            return;
        }

        var devices = client.get_devices();
        for (int i = 0; i < devices.length; i++) {
            var dev = devices[i];
            var connections = dev.get_available_connections();
            if (connections == null) {
                continue;
            }
            for (int j = 0; j < connections.length; j++) {
                var b = new ConnectionItem(dev, connections[j]);
                content.add(b);
            }
        }
    }

    /** Unused currently */
    void init_applet()
    {
        if (client == null) {
            return;
        }
        var con = client.get_primary_connection();
        if (con == null) {
            /* Reset?? */
            return;
        }
        var relcon = settings.get_connection_by_path(con.connection);
        var dev = con.get_devices()[0];
        switch (dev.get_device_type()) {
            case NM.DeviceType.WIFI:
                break;
            case NM.DeviceType.ETHERNET:
                break;
            default:
                break;
        }
    }

} // End class
