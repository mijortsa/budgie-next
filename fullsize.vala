/*
 * fullsize.vala
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

public class Fullsize : Gtk.ApplicationWindow
{

    Gdk.Rectangle scr;
    int intended_height = 42;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;

    PanelPosition position = PanelPosition.TOP;
    bool expanded = true;

    public Fullsize(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.POPUP_MENU);
        destroy.connect(Gtk.main_quit);

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
        // Revisit to account for multiple monitors..
        move(0, 0);
        show_all();
        set_expanded(false);

        warning("FOCUS BREAKS IN THIS DEMO!");
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

        register_menu_button(button);

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
        register_popover(popover);
        layout.pack_start(mainbtn, false, false, 10);
    }

    /**
     * Register a popover with expansion system. In future we'll add the
     * ability for menubar like behaviour
     *
     * TODO: Expand immediately before and after change events
     */
    void register_popover(Gtk.Popover? popover)
    {
        if (popover == null) {
            return;
        }
        popover.map.connect(()=> {
            set_expanded(true);
        });
        popover.notify["visible"].connect(()=> {
            if (!popover.get_visible()) {
                set_expanded(false);
            }
        });
    }

    void register_menu_button(Gtk.MenuButton? button)
    {
        if (button == null || !button.use_popover) {
            return;
        }
        button.can_focus = false;
        register_popover(button.popover);
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = orig_scr.width;
        n = orig_scr.width;
    }
    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = orig_scr.width;
        n = orig_scr.width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = orig_scr.height;
        n = orig_scr.height;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = orig_scr.height;
        n = orig_scr.height;
    }

    public void set_expanded(bool expanded)
    {
        if (this.expanded == expanded) {
            return;
        }
        this.expanded = expanded;

        var exp_scr = expanded ? orig_scr : small_scr;

        Cairo.RectangleInt r = Cairo.RectangleInt()
            {  x = 0, y = 0, width = exp_scr.width, height = exp_scr.height };
        var region = new Cairo.Region.rectangle(r);
        input_shape_combine_region(region);

        can_focus = expanded;

        message("W: %d, H: %d", r.width, r.height);
        if (expanded) {
            present();
        }
    }
}

} // End namespace

static Budgie.Fullsize instance = null;

static void app_start(Application? app)
{
    if (instance == null) {
        instance = new Budgie.Fullsize(app as Gtk.Application);
    }
}

public static int main(string[] args)
{
    var app = new Gtk.Application("com.solus-project.Fullsize", 0);
    app.activate.connect(app_start);

    return app.run();
}
