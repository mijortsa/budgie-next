/*
 * panel.vala
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

class PopoverManager {
    HashTable<Gtk.Widget?,Gtk.Popover?> widgets;

    unowned Slat? owner;

    public PopoverManager(Slat? owner)
    {
        this.owner = owner;
        widgets = new HashTable<Gtk.Widget?,Gtk.Popover?>(direct_hash, direct_equal);
    }

    public void register_popover(Gtk.Widget? widg, Gtk.Popover? popover)
    {
        if (widgets.contains(widg)) {
            return;
        }
        if (widg is Gtk.MenuButton) {
            (widg as Gtk.MenuButton).can_focus = false;
        } 
        /* TODO: Disconnect signals when deconstructing */
        popover.map.connect(()=> {
            owner.set_expanded(true);
        });
        popover.notify["visible"].connect(()=> {
            if (!popover.get_visible()) {
                owner.set_expanded(false);
            }
        });
        widgets.insert(widg, popover);
    }
}

public class Slat : Gtk.ApplicationWindow
{

    Gdk.Rectangle scr;
    int intended_height = 42;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;

    PanelPosition position = PanelPosition.TOP;
    PopoverManager manager;
    bool expanded = true;

    public Slat(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        manager = new PopoverManager(this);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;

        // TODO: Track
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out orig_scr);

        /* Smaller.. */
        small_scr = orig_scr;
        small_scr.height = intended_height;

        scr = small_scr;

        layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        layout.set_size_request(scr.width, intended_height);
        layout.vexpand = false;
        vexpand = false;
        add(layout);
        layout.valign = Gtk.Align.START;

        demo_code();

        realize();
        Budgie.set_struts(this, position, intended_height);
        move(orig_scr.x, orig_scr.y);
        show_all();
        set_expanded(false);
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

        var saction = new SimpleAction("quit", null);
        saction.activate.connect(()=> {
            application.quit();
        });
        application.add_action(saction);
        menu.append("Quit demo", "app.quit");
        button.menu_model = menu;

        manager.register_popover(button, button.popover);

        /* Emulate Budgie Menu Applet */
        var mainbtn = new Gtk.Button.from_icon_name("start-here", Gtk.IconSize.SMALL_TOOLBAR);
        mainbtn.can_focus = false;
        var popover = new BudgieMenuWindow(mainbtn);
        mainbtn.button_press_event.connect((e)=> {
            if (e.button != 1) {
                return Gdk.EVENT_PROPAGATE;
            }
            popover.show_all();
            return Gdk.EVENT_STOP;
        });
        manager.register_popover(mainbtn, popover);
        layout.pack_start(mainbtn, false, false, 10);
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

    public void set_expanded(bool expanded)
    {
        if (this.expanded == expanded) {
            return;
        }
        this.expanded = expanded;
        if (!expanded) {
            scr = small_scr;
        } else {
            scr = orig_scr;
        }
        queue_resize();
        if (expanded) {
            present();
        }
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
