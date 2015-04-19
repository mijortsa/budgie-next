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
    unowned Gtk.Popover? visible_popover = null;

    public PopoverManager(Slat? owner)
    {
        this.owner = owner;
        widgets = new HashTable<Gtk.Widget?,Gtk.Popover?>(direct_hash, direct_equal);

        owner.focus_out_event.connect(()=>{
            if (visible_popover != null) {
                visible_popover.hide();
                visible_popover = null;
            }
            return Gdk.EVENT_PROPAGATE;
        });
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
            } else {
                this.visible_popover = popover;
            }
        });
        widgets.insert(widg, popover);
    }
}

public class MainPanel : Gtk.Box
{
    public int intended_size;

    public MainPanel(int size)
    {
        Object(orientation: Gtk.Orientation.HORIZONTAL);
        this.intended_size = size;
        get_style_context().add_class("main-panel");
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = intended_size;
        n = intended_size;
    }
}
public class Slat : Gtk.ApplicationWindow
{

    Gdk.Rectangle scr;
    int intended_height = 42 + 5;
    Gdk.Rectangle small_scr;
    Gdk.Rectangle orig_scr;

    Gtk.Box layout;
    Gtk.Box main_layout;

    PanelPosition position = PanelPosition.TOP;
    PopoverManager manager;
    bool expanded = true;
    Gtk.ToggleButton? toggle;

    NCenter ncenter;

    public Slat(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        load_css();

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

        main_layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(main_layout);


        layout = new MainPanel(intended_height - 5);
        layout.vexpand = false;
        vexpand = false;
        main_layout.pack_start(layout, false, false, 0);
        main_layout.valign = Gtk.Align.START;

        /* Shadow.. */
        var shadow = new Budgie.HShadowBlock();
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        shadow.required_size = orig_scr.width;
        main_layout.pack_start(shadow, false, false, 0);

        demo_code();

        ncenter = new NCenter(intended_height - 5);
        ncenter.size_allocate.connect(()=> {
            if (!ncenter.get_visible()) {
                return;
            }
            shadow.required_size = (main_layout.get_allocated_width() - ncenter.get_allocated_width())+5;
            shadow.queue_resize();
        });
        ncenter.notify["visible"].connect(()=> {
            if (!ncenter.get_visible()) {
                shadow.required_size = orig_scr.width;
                shadow.queue_resize();
            }
        });

        realize();
        Budgie.set_struts(this, position, intended_height - 5);
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
        button.relief = Gtk.ReliefStyle.NONE;
        return button;
    }

    void load_css()
    {
        try {
            var f = File.new_for_uri("resource://com/solus-project/budgie/panel/style.css");
            var css = new Gtk.CssProvider();
            css.load_from_file(f);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);            
        } catch (Error e) {
            warning("CSS Missing: %s", e.message);
        }
    }

    void demo_code()
    {
        /* Emulate Budgie Menu Applet */
        var mainbtn = new Gtk.Button.from_icon_name("start-here", Gtk.IconSize.SMALL_TOOLBAR);
        mainbtn.margin_left = 10;
        mainbtn.relief = Gtk.ReliefStyle.NONE;
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

        toggle = new Gtk.ToggleButton.with_label("00:00:00");
        toggle.relief = Gtk.ReliefStyle.NONE;
        toggle.clicked.connect(()=> {
            ncenter.set_expanded(toggle.get_active());
        });
        layout.pack_end(toggle, false, false, 0);

        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);
        update_clock();
    }

    protected bool update_clock()
    {
        var time = new DateTime.now_local();
        var ctime = time.format("%H:%M");
        (toggle.get_child() as Gtk.Label).set_markup(ctime);

        return true;
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
