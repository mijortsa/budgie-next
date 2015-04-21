/*
 * ncenter.vala
 * 
 * Copyright 2015 Ikey Doherty <ikey@solus-project.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 */

[DBus (name="org.freedesktop.DisplayManager.Seat")]
public interface DMSeat : Object
{
    public abstract void lock() throws IOError;
}

public class HeaderWidget : Gtk.EventBox
{
    private string _title;

    public string title {
        public set {
            this._title = value;
            this.label.set_markup(title);
        }
        public get {
            return this._title;
        }
    }

    private Gtk.Label label;

    public HeaderWidget(string title)
    {
        label = new Gtk.Label(title);
        add(label);
        this.title = title;
        label.halign = Gtk.Align.START;

        label.margin = 10;
        label.margin_left = 20;

        show_all();

        get_style_context().add_class("header-widget");
    }
}


public class NCenter : Gtk.Window
{
    Gtk.Box layout;
    Gtk.Box main_layout;
    int our_width;
    int our_height;
    DMSeat? proxy;

    private double scale = 0.0;

    public double nscale {
        public set {
            scale = value;
            if (nscale > 0.0 && nscale < 1.0) {
                required_size = (int)(get_allocated_width() * nscale);
            } else {
                required_size = get_allocated_width();
            }
            queue_draw();
        }
        public get {
            return scale;
        }
    }

    // Hacky, but just says how far to offset our window.
    int offset;

    public int required_size { public get ; protected set; }

    public NCenter(int offset)
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);
        this.offset = offset;

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        resizable = false;
        set_keep_above(true);

        layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(main_layout);

        var shadow = new Budgie.VShadowBlock();
        main_layout.pack_start(shadow, false, false, 0);
        main_layout.pack_start(layout, true, true, 0);

        layout.get_style_context().add_class("notification-center");


        /* Demo code */
        var header = new HeaderWidget("Media");
        layout.pack_start(header, false, false, 2);
        header.margin_top = 10;
        header.margin_bottom = 10;

        var mpris = new MprisWidget();
        mpris.margin_left = 20;
        layout.pack_start(mpris, false, false, 0);

        header = new HeaderWidget("Audio");
        layout.pack_start(header, false, false, 2);
        header.margin_top = 20;
        header.margin_bottom = 10;
        var audio = new AudioPane();
        audio.margin_left = 20;
        audio.margin_right = 20;
        layout.pack_start(audio, false, false, 0);

        var bottom = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        var wrap = new Gtk.EventBox();
        bottom.margin_top = 10;
        bottom.margin_bottom = 10;
        wrap.get_style_context().add_class("header-widget");
        bottom.halign = Gtk.Align.CENTER;
        wrap.margin_bottom = 40;
        wrap.add(bottom);
        layout.pack_end(wrap, false, false, 0);

        var btn = new Gtk.Button.from_icon_name("preferences-system-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            /* TODO: Drop gnome-control-center like its hot. */
            try {
                Process.spawn_command_line_async("gnome-control-center");
            } catch (Error e) {
                message("Error invoking gnome-control-center: %s", e.message);
            }
        });
        btn.halign = Gtk.Align.START;
        btn.relief = Gtk.ReliefStyle.NONE;
        btn.margin_left = 20;
        bottom.pack_start(btn, false, false, 0);
        btn = new Gtk.Button.from_icon_name("system-shutdown-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            try {
                Process.spawn_command_line_async("budgie-session-dialog");
            } catch (Error e) {
                message("Error invoking end session dialog: %s", e.message);
            }
        });
        btn.halign = Gtk.Align.START;
        btn.relief = Gtk.ReliefStyle.NONE;
        btn.margin_left = 20;
        bottom.pack_start(btn, false, false, 0);

        btn = new Gtk.Button.from_icon_name("system-lock-screen-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        btn.clicked.connect(()=> {
            lock_screen();
        });
        btn.halign = Gtk.Align.START;
        btn.relief = Gtk.ReliefStyle.NONE;
        btn.margin_left = 20;
        bottom.pack_start(btn, false, false, 0);

        var path = Environment.get_variable("XDG_SEAT_PATH");
        if (path == null) {
            btn.no_show_all = true;
            btn.hide();
        }
        layout.show_all();

        placement();
        get_child().show_all();
    }

    public override bool draw(Cairo.Context cr)
    {
        if (nscale == 0.0 || nscale == 1.0) {
            return base.draw(cr);
        }

        Gtk.Allocation alloc;
        get_allocation(out alloc);
        var buffer = new Cairo.ImageSurface(Cairo.Format.ARGB32, alloc.width, alloc.height);
        var cr2 = new Cairo.Context(buffer);

        propagate_draw(get_child(), cr2);
        var width = alloc.width * nscale;

        cr.set_source_surface(buffer, alloc.width-width, 0);
        cr.paint();

        return Gdk.EVENT_STOP;
    }

    /**
     * In future this will handle sliding ncenter into view.. */
    public void set_expanded(bool exp)
    {
        double old_op, new_op;
        if (exp) {
            old_op = 0.0;
            new_op = 1.0;
        } else {
            old_op = 1.0;
            new_op = 0.0;
        }
        nscale = old_op;

        if (exp) {
            show_all();
        }

        var anim = new Budgie.Animation();
        anim.widget = this;
        anim.length = 270 * Budgie.MSECOND;
        anim.tween = Budgie.sine_ease_in;
        anim.changes = new Budgie.PropChange[] {
            Budgie.PropChange() {
                property = "nscale",
                old = old_op,
                @new = new_op
            },
            Budgie.PropChange() {
                property = "opacity",
                old = old_op,
                @new = new_op
            }
        };

        anim.start((a)=> {
            if ((a.widget as NCenter).nscale == 0.0) {
                a.widget.hide();
            } else {
                (a.widget as Gtk.Window).present();
            }
        });
    }

    void lock_screen()
    {
        var path = Environment.get_variable("XDG_SEAT_PATH");

        try {
            if (proxy == null) {
                proxy = Bus.get_proxy_sync(BusType.SYSTEM, "org.freedesktop.DisplayManager", path);
            }
            proxy.lock();
        } catch (Error e) {
            warning(e.message);
            proxy = null;
            return;
        }
    }

    public override void get_preferred_width(out int m, out int n)
    {
        m = our_width;
        n = our_width;
    }

    public override void get_preferred_width_for_height(int h, out int m, out int n)
    {
        m = our_width;
        n = our_width;
    }

    public override void get_preferred_height(out int m, out int n)
    {
        m = our_height;
        n = our_height;
    }

    public override void get_preferred_height_for_width(int w, out int m, out int n)
    {
        m = our_height;
        n = our_height;
    }

    void placement()
    {
        Gdk.Rectangle scr;
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out scr);

        var width = (int) (scr.width * 0.16);
        our_width = width;
        our_height = scr.height - offset;
        if (!get_realized()) {
            realize();
        }
        move(scr.x + (scr.width-width), scr.y+offset);
    }
}
