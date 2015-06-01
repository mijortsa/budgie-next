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

class PopoverManager : Object {
    HashTable<Gtk.Widget?,Gtk.Popover?> widgets;

    unowned Budgie.Slat? owner;
    unowned Gtk.Popover? visible_popover = null;

    bool grabbed = false;
    bool mousing = false;


    public PopoverManager(Budgie.Slat? owner)
    {
        this.owner = owner;
        widgets = new HashTable<Gtk.Widget?,Gtk.Popover?>(direct_hash, direct_equal);

        owner.focus_out_event.connect(()=>{
            if (mousing) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (visible_popover != null) {
                visible_popover.hide();
                make_modal(visible_popover, false);
                visible_popover = null;
            }
            return Gdk.EVENT_PROPAGATE;
        });
        owner.button_press_event.connect((w,e)=> {
            if (!grabbed) {
                return Gdk.EVENT_PROPAGATE;
            }
            Gtk.Allocation alloc;
            visible_popover.get_allocation(out alloc);

            if (owner.position == PanelPosition.BOTTOM) {
                /* GTK is on serious amounts of crack, Y is always 0. */
                Gtk.Allocation parent;
                owner.get_allocation(out parent);
                alloc.y = parent.height - alloc.height;
            }
            if ((e.x < alloc.x || e.x > alloc.x+alloc.width) ||
                (e.y < alloc.y || e.y > alloc.y+alloc.height)) {
                    visible_popover.hide();
                    make_modal(visible_popover, false);
                    visible_popover = null;
            }
            return Gdk.EVENT_STOP;

        });
        owner.add_events(Gdk.EventMask.POINTER_MOTION_MASK | Gdk.EventMask.ENTER_NOTIFY_MASK | Gdk.EventMask.BUTTON_PRESS_MASK);
    }

    void make_modal(Gtk.Popover? pop, bool modal = true)
    {
        if (pop == null || pop.get_window() == null || mousing) {
            return;
        }
        if (modal) {
            if (grabbed) {
                return;
            }
            Gtk.grab_add(owner);
            owner.set_focus(null);
            pop.grab_focus();
            grabbed = true;
        } else {
            if (!grabbed) {
                return;
            }
            Gtk.grab_remove(owner);
            owner.grab_focus();
            grabbed = false;
        }
    }

    public void unregister_popover(Gtk.Widget? widg)
    {
        if (!widgets.contains(widg)) {
            return;
        }
        widgets.remove(widg);
    }

    public void register_popover(Gtk.Widget? widg, Gtk.Popover? popover)
    {
        if (widgets.contains(widg)) {
            return;
        }
        if (widg is Gtk.MenuButton) {
            (widg as Gtk.MenuButton).can_focus = false;
        } 
        popover.map.connect((p)=> {
            owner.set_expanded(true);
            this.visible_popover = p as Gtk.Popover;
            make_modal(this.visible_popover);
        });
        popover.closed.connect((p)=> {
            if (!mousing && grabbed) {
                make_modal(p, false);
                visible_popover = null;
            }
        });
        widg.enter_notify_event.connect((w,e)=> {
            if (mousing) {
                return Gdk.EVENT_PROPAGATE;
            }
            if (grabbed) {
                if (widgets.contains(w)) {
                    if (visible_popover != widgets[w] && visible_popover != null) {
                        /* Hide current popover, re-open next */
                        mousing = true;
                        visible_popover.hide();
                        visible_popover = widgets[w];
                        visible_popover.show_all();
                        owner.set_focus(null);
                        visible_popover.grab_focus();
                        mousing = false;
                    }
                }
                return Gdk.EVENT_STOP;
            }
            return Gdk.EVENT_PROPAGATE;
        });
        popover.notify["visible"].connect(()=> {
            if (mousing || grabbed) {
                return;
            }
            if (!popover.get_visible()) {
                make_modal(visible_popover, false);
                visible_popover = null;
                owner.set_expanded(false);
            }
        });
        popover.destroy.connect((w)=> {
            widgets.remove(w);
        });
        popover.modal = false;
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

    public PanelPosition position = PanelPosition.TOP;
    PopoverManager manager;
    bool expanded = true;
    Gtk.ToggleButton? toggle;
    TrayApplet? tray;

    NCenter ncenter;
    Budgie.HShadowBlock shadow;

    public Slat(Gtk.Application? app)
    {
        Object(application: app, type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        load_css();

        get_settings().set_property("gtk-application-prefer-dark-theme", true);

        manager = new PopoverManager(this);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("Compositing not available, things will Look Bad (TM)");
        } else {
            set_visual(vis);
        }
        resizable = false;
        app_paintable = true;
        get_style_context().add_class("budgie-container");

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
        shadow = new Budgie.HShadowBlock();
        shadow.hexpand = false;
        shadow.halign = Gtk.Align.START;
        shadow.show_all();
        shadow.required_size = orig_scr.width;
        main_layout.pack_start(shadow, false, false, 0);

        demo_code();

        ncenter = new NCenter(position, intended_height - 5);
        ncenter.bind_property("required-size", shadow, "required-size", BindingFlags.DEFAULT, (b,v, ref v2)=> {
            var d = (main_layout.get_allocated_width()-v.get_int()) + 5;
            v2 = Value(typeof(int));
            v2.set_int(d);
            return true;
        });
        ncenter.notify["visible"].connect(()=> {
            if (!ncenter.get_visible()) {
                shadow.required_size = orig_scr.width;
                shadow.queue_resize();
            }
        });

        realize();
        placement();
        get_child().show_all();
        set_expanded(false);

        shadow.hide();

        Idle.add(fade_in);
    }

    bool fade_in()
    {
        opacity = 0.0;
        show();
        var anim = new Budgie.Animation();
        anim.widget = this;
        anim.length = 400 * Budgie.MSECOND;
        anim.tween = Budgie.sine_ease_in;
        anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "opacity",
                old = 0.0,
                @new = 1.0
            }
        };

        anim.start(null);
        return false;
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
            if (popover.get_visible()) {
                popover.hide();
            } else {
                popover.show_all();
            }
            return Gdk.EVENT_STOP;
        });
        manager.register_popover(mainbtn, popover);
        layout.pack_start(mainbtn, false, false, 10);

        var tasklist = new IconTasklistApplet();
        layout.pack_start(tasklist, true, true, 10);

        toggle = new Gtk.ToggleButton.with_label("00:00:00");
        toggle.relief = Gtk.ReliefStyle.NONE;
        toggle.margin_right = 5;
        toggle.get_style_context().add_class("clock");
        toggle.clicked.connect(()=> {
            ncenter.set_expanded(toggle.get_active());
            if (toggle.get_active()) {
                layout.get_style_context().add_class("expanded");
                shadow.show();
            } else {
                layout.get_style_context().remove_class("expanded");
                shadow.hide();
            }
        });
        layout.pack_end(toggle, false, false, 0);

        tray = new TrayApplet();
        layout.pack_end(tray, false, false, 0);

        Timeout.add_seconds_full(GLib.Priority.LOW, 1, update_clock);
        update_clock();
    }

    protected bool update_clock()
    {
        var time = new DateTime.now_local();
        var ctime = time.format("%X");
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

    void placement()
    {
        Budgie.set_struts(this, position, intended_height - 5);
        switch (position) {
            case Budgie.PanelPosition.TOP:
                move(orig_scr.x, orig_scr.y);
                break;
            default:
                main_layout.valign = Gtk.Align.END;
                move(orig_scr.x, orig_scr.y+(orig_scr.height-intended_height));
                main_layout.reorder_child(shadow, 0);
                shadow.get_style_context().add_class("bottom");
                set_gravity(Gdk.Gravity.SOUTH);
                break;
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
