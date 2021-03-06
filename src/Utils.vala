/*
* Copyright © 2019 Alain M. (https://github.com/alainm23/planner)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alain M. <alain23@protonmail.com>
*/

public class Utils : GLib.Object {
    public string CACHE_FOLDER;
    public string PROFILE_FOLDER;
    public string WEBVIEW_STYLESHEET = """
        html {
            font-size: 16px;
        }
        p {
            display: block;
            margin-block-start: 1em;
            margin-block-end: 1em;
            margin-inline-start: 0px;
            margin-inline-end: 0px;
            font-size: 1rem;
            color: %s;
        }
        h1,
        h2,
        h3,
        h4,
        h5,
        h6 {
            font-weight: 600;
            line-height: 1.25;
            margin-bottom: 16px;
            margin-top: 12px;
        }
        h1 {
            border-bottom: 1px solid #eaecef;
            font-size: 2em;
        }
        h2 {
            border-bottom: 1px solid #eaecef;
            padding-bottom: .3em;
            font-size: 1.5em;
        }
        h3 {
            font-size: 1.25em;
        }
        h4 {
            font-size: 1em;
        }
        h5 {
            font-size: .875em;
        }
        h6 {
            font-size: .85em;
        }
        small {
            font-size: .7em;
        }
        canvas,
        iframe,
        video,
        svg,
        select,
        textarea {
            display: block;
            max-width: 50%;
        }
        body{
            color: %s;
            background-color: %s;
            font-family: 'Open Sans', Helvetica, sans-serif;
            font-weight: 400;
            line-height: 1.5;
            margin-left: 36px;
            margin-right: 36px;
            margin-top: 12px;
            max-width: 100%;
            text-align: left;
            word-wrap: break-word;
            /*white-space: pre-line;*/
        }
        table {
            border-spacing: 0;
            border-collapse: collapse;
            margin-top: 0;
            margin-bottom: 16px;
        }
        table th {
            font-weight: bold;
            background-color: #E7E7E7;
        }
        table th,
        table td {
            padding: 8px 13px;
            border: 1px solid #EAEAEA;
        }
        table tr {
            border-top: 1px solid #EAEAEA;
        }
        img {
            height:auto;
            width: 300px;
            object-fit:cover;
        }
        img[src*='#image-src'] {
            float:center;
            height:auto;
            width: 300px;
        }
        a,
        a:visited,
        a:hover,
        a:focus,
        a:active {
            color: #3daee9;
        }
        code {
            border: 0;
            display: inline;
            line-height: inherit;
            margin: 0;
            max-width: auto;
            overflow: visible;
            padding: 0;
            word-wrap: normal;
        }
        blockquote {
            margin: 0;
            border-left: 5px solid #3daee9;
            font-style: italic;
            padding-left: .8rem;
            text-align: left;
        }
        pre {
            background-color: #f6f8fa;
            border-radius: 3px;
            font-size: 85%;
            line-height: 1.45;
            overflow: auto;
            padding: 16px;
        }
        ul,
        ol,
        li {
            text-align: left;
            color: %s;
        }
    """;

    public Utils () {
        CACHE_FOLDER = GLib.Path.build_filename (GLib.Environment.get_user_cache_dir (), "com.github.alainm23.planner");
        PROFILE_FOLDER = GLib.Path.build_filename (CACHE_FOLDER, "profile");
    }

    public void create_dir_with_parents (string dir) {
        string path = Environment.get_home_dir () + dir;
        File tmp = File.new_for_path (path);
        if (tmp.query_file_type (0) != FileType.DIRECTORY) {
            GLib.DirUtils.create_with_parents (path, 0775);
        }
    }

    public void update_images_credits () {
        new Thread<void*> ("update_images_credits", () => {
            try {
                var parser = new Json.Parser ();
                parser.load_from_file ("/usr/share/com.github.alainm23.planner/credits.json");

                var root = parser.get_root ().get_object ();

                var developers = root.get_array_member ("developing");
                var designers = root.get_array_member ("design");
                var translators = root.get_array_member ("translation");
                var supports = root.get_array_member ("support");

                foreach (var _item in developers.get_elements ()) {
                    var item = _item.get_object ();
                    download_profile_image (item.get_string_member ("id"), item.get_string_member ("avatar"));
                }

                foreach (var _item in designers.get_elements ()) {
                    var item = _item.get_object ();
                    download_profile_image (item.get_string_member ("id"), item.get_string_member ("avatar"));
                }

                foreach (var _item in translators.get_elements ()) {
                    var item = _item.get_object ();
                    download_profile_image (item.get_string_member ("id"), item.get_string_member ("avatar"));
                }

                foreach (var _item in supports.get_elements ()) {
                    var item = _item.get_object ();
                    download_profile_image (item.get_string_member ("id"), item.get_string_member ("avatar"));
                }
            } catch (Error e) {
                print ("Error: %s\n", e.message);
            }

            return null;
        });
    }

    public void download_profile_image (string id, string avatar) {
        // Create file
        var image_path = GLib.Path.build_filename (Application.utils.PROFILE_FOLDER, ("%s.jpg").printf (id));

        var file_path = File.new_for_path (image_path);
        var file_from_uri = File.new_for_uri (avatar);
        if (file_path.query_exists () == false) {
            MainLoop loop = new MainLoop ();

            file_from_uri.copy_async.begin (file_path, 0, Priority.DEFAULT, null, (current_num_bytes, total_num_bytes) => {
                // Report copy-status:
                print ("%" + int64.FORMAT + " bytes of %" + int64.FORMAT + " bytes copied.\n", current_num_bytes, total_num_bytes);
            }, (obj, res) => {
                try {
                    if (file_from_uri.copy_async.end (res)) {
                        print ("Avatar Profile Downloaded\n");
                    }
                } catch (Error e) {
                    print ("Error: %s\n", e.message);
                }

                loop.quit ();
            });

            loop.run ();
        }
    }

    public string convert_invert (string hex) {
        var gdk_white = Gdk.RGBA ();
        gdk_white.parse ("#fff");

        var gdk_black = Gdk.RGBA ();
        gdk_black.parse ("#000");

        var gdk_bg = Gdk.RGBA ();
        gdk_bg.parse (hex);

        var contrast_white = contrast_ratio (
            gdk_bg,
            gdk_white
        );

        var contrast_black = contrast_ratio (
            gdk_bg,
            gdk_black
        );

        var fg_color = "#fff";

        // NOTE: We cheat and add 3 to contrast when checking against black,
        // because white generally looks better on a colored background
        if (contrast_black > (contrast_white + 3)) {
            fg_color = "#000";
        }

        return fg_color;
    }

    private double contrast_ratio (Gdk.RGBA bg_color, Gdk.RGBA fg_color) {
        var bg_luminance = get_luminance (bg_color);
        var fg_luminance = get_luminance (fg_color);

        if (bg_luminance > fg_luminance) {
            return (bg_luminance + 0.05) / (fg_luminance + 0.05);
        }

        return (fg_luminance + 0.05) / (bg_luminance + 0.05);
    }

    private double get_luminance (Gdk.RGBA color) {
        var red = sanitize_color (color.red) * 0.2126;
        var green = sanitize_color (color.green) * 0.7152;
        var blue = sanitize_color (color.blue) * 0.0722;

        return (red + green + blue);
    }

    private double sanitize_color (double color) {
        if (color <= 0.03928) {
            return color / 12.92;
        }

        return Math.pow ((color + 0.055) / 1.055, 2.4);
    }

    public string rgb_to_hex_string (Gdk.RGBA rgba) {
        string s = "#%02x%02x%02x".printf(
            (uint) (rgba.red * 255),
            (uint) (rgba.green * 255),
            (uint) (rgba.blue * 255));
        return s;
    }

    public bool is_label_repeted (Gtk.FlowBox flowbox, int id) {
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            var child = element as Widgets.LabelChild;
            if (child.label.id == id) {
                return true;
            }
        }

        return false;
    }

    public bool is_empty (Gtk.FlowBox flowbox) {
        int l = 0;
        foreach (Gtk.Widget element in flowbox.get_children ()) {
            l = l + 1;
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    public bool is_listbox_empty (Gtk.ListBox listbox) {
        int l = 0;
        foreach (Gtk.Widget element in listbox.get_children ()) {
            var item = element as Widgets.TaskRow;

            if (item.task.checked == 0) {
                l = l + 1;
            }
        }

        if (l <= 0) {
            return true;
        } else {
            return false;
        }
    }

    public bool is_listbox_all_empty (Gtk.ListBox listbox) {
        int l = 0;
        foreach (Gtk.Widget element in listbox.get_children ()) {
            l = l + 1;
        }

        return (l <= 0);
    }

    public bool is_task_repeted (Gtk.ListBox listbox, int id) {
        foreach (Gtk.Widget element in listbox.get_children ()) {
            var item = element as Widgets.TaskRow;

            if (id == item.task.id) {
                return true;
            }
        }

        return false;
    }

    public bool is_tomorrow (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ().add_days (1);
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }

    public bool is_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();
        return date_1.get_day_of_year () == date_2.get_day_of_year () && date_1.get_year () == date_2.get_year ();
    }

    public bool is_before_today (GLib.DateTime date_1) {
        var date_2 = new GLib.DateTime.now_local ();

        if (date_1.compare(date_2) == -1) {
            return true;
        }

        return false;
    }

    public bool is_current_month (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            if (date.get_month () == now.get_month ()) {
                return true;
            } else {
                return false;
            }
        } else {
            return false;
        }
    }

    public bool is_upcoming (GLib.DateTime date) {
        if (is_today (date) == false && is_before_today (date) == false) {
            return true;
        } else {
            return false;
        }
    }

    public string first_letter_to_up (string text) {
        string l = text.substring (0, 1);
        return l.up () + text.substring (1);
    }

    public int get_days_of_month (int index) {
        if ((index == 1) || (index == 3) || (index == 5) || (index == 7) || (index == 8) || (index == 10) || (index == 12)) {
            return 31;
        } else if ((index == 2) || (index == 4) || (index == 6) || (index == 9) || (index == 11)) {
            return 30;
        } else {
            var date = new GLib.DateTime.now_local ();
            int year = date.get_year ();

            if (year % 4 == 0) {
                if (year % 100 == 0) {
                    if (year % 400 == 0) {
                        return 29;
                    } else {
                        return 28;
                    }
                } else {
                    return 28;
                }
            } else {
                return 28;
            }
        }
    }

    public string get_weather_icon_name (string key) {
        var weather_icon_name = new Gee.HashMap<string, string> ();

        weather_icon_name.set ("01d", "weather-clear-symbolic");
        weather_icon_name.set ("01n", "weather-clear-night-symbolic");
        weather_icon_name.set ("02d", "weather-few-clouds-symbolic");
        weather_icon_name.set ("02n", "weather-few-clouds-night-symbolic");
        weather_icon_name.set ("03d", "weather-overcast-symbolic");
        weather_icon_name.set ("03n", "weather-overcast-symbolic");
        weather_icon_name.set ("04d", "weather-overcast-symbolic");
        weather_icon_name.set ("04n", "weather-overcast-symbolic");
        weather_icon_name.set ("09d", "weather-showers-symbolic");
        weather_icon_name.set ("09n", "weather-showers-symbolic");
        weather_icon_name.set ("10d", "weather-showers-scattered-symbolic");
        weather_icon_name.set ("10n", "weather-showers-scattered-symbolic");
        weather_icon_name.set ("11d", "weather-storm-symbolic");
        weather_icon_name.set ("11n", "weather-storm-symbolic");
        weather_icon_name.set ("13d", "weather-snow-symbolic");
        weather_icon_name.set ("13n", "weather-snow-symbolic");
        weather_icon_name.set ("50d", "weather-fog-symbolic");
        weather_icon_name.set ("50n", "weather-fog-symbolic");

        return weather_icon_name.get (key);
    }

    public string get_weaher_color (string key) {
        var weather_colors = new GLib.HashTable<string, string> (str_hash, str_equal);

        weather_colors.insert("weather-overcast-symbolic", "#68758e");
        weather_colors.insert("weather-showers-symbolic", "#68758e");
        weather_colors.insert("weather-showers-scattered-symbolic", "#68758e");
        weather_colors.insert("weather-storm-symbolic", "#555c68");
        weather_colors.insert("weather-snow-symbolic", "#9ca7ba");
        weather_colors.insert("weather-fog-symbolic", "#a1a6af");

        return weather_colors.get (key);
    }

    public string get_weather_description (string key) {
        var weather_descriptions = new GLib.HashTable<string, string> (str_hash, str_equal);

        weather_descriptions.insert("Clouds", _("Clouds"));
        weather_descriptions.insert("Clear", _("Clear"));
        weather_descriptions.insert("Atmosphere", _("Atmosphere"));
        weather_descriptions.insert("Snow", _("Snow"));
        weather_descriptions.insert("Rain", _("Rain"));
        weather_descriptions.insert("Drizzle", _("Drizzle"));
        weather_descriptions.insert("Thunderstorm", _("Thunderstorm"));

        return weather_descriptions.get (key);
    }

    public string get_weather_description_detail (string key) {
        var details = new GLib.HashTable<string, string> (str_hash, str_equal);

        details.insert("200", _("Thunderstorm with light rain"));
        details.insert("201", _("Thunderstorm with rain"));
        details.insert("202", _("Thunderstorm with heavy rain"));
        details.insert("210", _("Light thunderstorm"));
        details.insert("211", _("Thunderstorm"));
        details.insert("212", _("Heavy thunderstorm"));
        details.insert("221", _("Ragged thunderstorm"));
        details.insert("230", _("Thunderstorm with light drizzle"));
        details.insert("231", _("Thunderstorm with drizzle"));
        details.insert("232", _("Thunderstorm with heavy drizzle"));

        details.insert("300", _("Light intensity drizzle"));
        details.insert("301", _("Drizzle"));
        details.insert("302", _("Heavy intensity drizzle"));
        details.insert("310", _("Light intensity drizzle rain"));
        details.insert("311", _("Drizzle rain"));
        details.insert("312", _("Heavy intensity drizzle rain"));
        details.insert("313", _("Shower rain and drizzle"));
        details.insert("314", _("Heavy shower rain and drizzle"));
        details.insert("321", _("Shower drizzle"));

        details.insert("500", _("Light rain"));
        details.insert("501", _("Moderate rain"));
        details.insert("502", _("Heavy intensity rain"));
        details.insert("503", _("Very heavy rain"));
        details.insert("504", _("Extreme rain"));
        details.insert("511", _("Freezing rain"));
        details.insert("520", _("Light intensity shower rain"));
        details.insert("521", _("Shower rain"));
        details.insert("522", _("Heavy intensity shower rain"));
        details.insert("531", _("Ragged shower rain"));

        details.insert("600", _("Light snow"));
        details.insert("601", _("Snow"));
        details.insert("602", _("Heavy snow"));
        details.insert("611", _("Sleet"));
        details.insert("612", _("Shower sleet"));
        details.insert("615", _("Light rain and snow"));
        details.insert("616", _("Rain and snow"));
        details.insert("620", _("Light shower snow"));
        details.insert("621", _("Shower snow"));
        details.insert("622", _("Heavy shower snow"));

        details.insert("800", _("Clear sky"));
        details.insert("801", _("Few clouds"));
        details.insert("802", _("Scattered clouds"));
        details.insert("803", _("Broken clouds"));
        details.insert("804", _("Overcast clouds"));

        return details.get (key);
    }

    public string get_default_date_format (string date_string) {
        var now = new GLib.DateTime.now_local ();
        var date = new GLib.DateTime.from_iso8601 (date_string, new GLib.TimeZone.local ());

        if (date.get_year () == now.get_year ()) {
            return date.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date.format (Granite.DateTime.get_default_date_format (false, true, true));
        }
    }

    public string get_default_date_format_from_date (GLib.DateTime date) {
        var now = new GLib.DateTime.now_local ();

        if (date.get_year () == now.get_year ()) {
            return date.format (Granite.DateTime.get_default_date_format (false, true, false));
        } else {
            return date.format (Granite.DateTime.get_default_date_format (false, true, true));
        }
    }

    public string get_relative_default_date_format_from_date (GLib.DateTime date) {
        if (Application.utils.is_today (date)) {
            return _("Today");
        } else if (Application.utils.is_tomorrow (date)) {
            return _("Tomorrow");
        } else {
            return Application.utils.get_default_date_format_from_date (date);
        }
    }


    public string get_theme (int key) {
        var themes = new Gee.HashMap<int, string> ();

        themes.set (1, "#ffe16b");
        themes.set (2, "#3d4248");
        themes.set (3, "#64baff");
        themes.set (4, "#ed5353");
        themes.set (5, "#9bdb4d");
        themes.set (6, "#667885");
        themes.set (7, "#FA0080");

        return themes.get (key);
    }

    public void apply_theme (string hex) {
        string THEME_CLASS = """
            @define-color color_header %s;
            @define-color color_selected %s;
            @define-color color_text %s;
        """;

        var provider = new Gtk.CssProvider ();

        try {
            var colored_css = THEME_CLASS.printf (
                hex,
                hex,
                convert_invert (hex)
            );

            provider.load_from_data (colored_css, colored_css.length);

            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (GLib.Error e) {
            return;
        }
    }

    public GLib.DateTime strip_time (GLib.DateTime datetime) {
        return datetime.add_full (0, 0, 0, -datetime.get_hour (), -datetime.get_minute (), -datetime.get_second ());
    }

    public bool check_internet_connection () {
        var host = "www.google.com";

        try {
            // Resolve hostname to IP address
            var resolver = Resolver.get_default ();
            var addresses = resolver.lookup_by_name (host, null);
            var address = addresses.nth_data (0);
            if (address == null) {
                return false;
            }
        } catch (Error e) {
            debug ("%s\n", e.message);
            return false;
        }
        return true;
    }

    /*
    public void create_tutorial_project () {
        var tutorial = new Objects.Project ();
        tutorial.name = _("Meet Planner !!!");
        tutorial.note = _("This project shows you everything you need to know use Planner.\nDon't hesitateto play arount in it - you can always create a new one in 'Preferences > Help'");
        tutorial.color = "#f9c440";

        if (Application.database.add_project (tutorial) == Sqlite.DONE) {
            var last_project = Application.database.get_last_project ();

            var task_1 = new Objects.Task ();
            task_1.project_id = last_project.id;
            task_1.content = _("Complete this task");
            task_1.note = _("Complete it by taping the checkbox on the left.");
            Application.database.add_task (task_1);

            var task_2 = new Objects.Task ();
            task_2.project_id = last_project.id;
            task_2.content = _("Create a new task");
            task_2.note = _("Tap the '+' button down on the right to create a new task.");
            Application.database.add_task (task_2);

            var task_3 = new Objects.Task ();
            task_3.project_id = last_project.id;
            task_3.content = _("Put this task in Today");
            task_3.note = _("Tap the calendar button below to decide when you'll do this task. Choose Today with a double click.");
            Application.database.add_task (task_3);

            var task_4 = new Objects.Task ();
            task_4.project_id = last_project.id;
            task_4.content = _("Plan this task for later");
            task_4.note = _("Tap the calendar button again, but now, choose a date in the calendar. It will appear on your Today list when the day comes. While the day comes, this task appear in the Upcoming list.");
            Application.database.add_task (task_4);

            var task_5 = new Objects.Task ();
            task_5.project_id = last_project.id;
            task_5.content = _("Create a project");
            task_5.note = _("Do you want to group your tasks? On the left side, tap the '+' button to create a project.");
            Application.database.add_task (task_5);
        }
    }
    */
}
