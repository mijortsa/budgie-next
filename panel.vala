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

public class Slat : Gtk.ApplicationWindow
{

    Gdk.Rectangle scr;
    int intended_height = 42;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;

    public Slat(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.DOCK);
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

        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(layout);

        demo_code();

        realize();
        // Revisit to account for multiple monitors..
        move(0, 0);
        show_all();
        //present();
    }

    Gtk.MenuButton? mbutton(string title)
    {
        var label = new Gtk.Label(title);
        label.use_markup = true;
        var button = new Gtk.MenuButton();
        button.use_popover = true;
        button.add(label);
        return button;
    }

    void demo_code()
    {
        var button = mbutton("Button 1");
        layout.pack_start(button, false, false, 0);
        var menu = new Menu();
        var action = new PropertyAction("dark-theme", get_settings(), "gtk-application-prefer-dark-theme");
        application.add_action(action);
        menu.append("Dark theme", "app.dark-theme");
        button.menu_model = menu;
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

static Budgie.Slat instance = null;

static void app_start(Application? app)
{
    if (instance == null) {
        instance = new Budgie.Slat(app as Gtk.Application);
    }
}

public static int main(string[] args)
{
    var app = new Gtk.Application("com.solus-project.Slat", 0);
    app.activate.connect(app_start);

    return app.run();
}
