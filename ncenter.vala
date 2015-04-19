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

/**
 * Alternative to a separator, gives a shadow effect :)
 *
 * @note Until we need otherwise, this is a vertical only widget..
 */
public class ShadowBlock : Gtk.EventBox
{

    public ShadowBlock()
    {
        get_style_context().add_class("shadow-block");
    }

    public override void get_preferred_width(out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }

    public override void get_preferred_width_for_height(int height, out int min, out int nat)
    {
        min = 5;
        nat = 5;
    }
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

        label.margin = 20;
        show_all();

        get_style_context().add_class("header-widget");
    }
}


public class NCenter : Gtk.Window
{
    Gtk.Box layout;
    Gtk.Box main_layout;

    public NCenter()
    {
        Object(type_hint: Gdk.WindowTypeHint.DOCK);
        destroy.connect(Gtk.main_quit);

        get_settings().set_property("gtk-application-prefer-dark-theme", true);

        var vis = screen.get_rgba_visual();
        if (vis == null) {
            warning("No RGBA functionality");
        } else {
            set_visual(vis);
        }

        resizable = false;
        load_css();
        set_keep_above(true);

        layout = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_layout = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 0);
        add(main_layout);

        var shadow = new ShadowBlock();
        main_layout.pack_start(shadow, false, false, 0);
        main_layout.pack_start(layout, true, true, 0);

        layout.get_style_context().add_class("notification-center");


        /* Demo code */
        var header = new HeaderWidget("Music");
        layout.pack_start(header, false, false, 2);
        header.margin_top = 40;

        var mpris = new MprisWidget();
        mpris.margin_left = 20;
        layout.pack_start(mpris, false, false, 0);

        layout.show_all();

        placement();
        get_child().show_all();
        present();
    }

    void placement()
    {
        Gdk.Rectangle scr;
        var mon = screen.get_primary_monitor();
        screen.get_monitor_geometry(mon, out scr);

        var width = (int) (scr.width * 0.25);
        if (!get_realized()) {
            realize();
        }
        move(scr.x + (scr.width-width), scr.y);
        set_size_request(width, scr.height);
    }

    void load_css()
    {
        try {
            var f = File.new_for_path("style.css");
            var css = new Gtk.CssProvider();
            css.load_from_file(f);
            Gtk.StyleContext.add_provider_for_screen(screen, css, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);            
        } catch (Error e) {
            warning("CSS Missing: %s", e.message);
        }
    }
}

public static void main(string[] args)
{
    Gtk.init(ref args);
    var center = new NCenter();
    Gtk.main();
    center = null;
}
