import QtQuick

// Current weather + a short forecast from Open-Meteo (free, no API key).
// Location: the city typed in the editor, else a one-off IP lookup.
// Lives in main.qml so the clock tile can be recreated without refetching.
QtObject {
    id: weather

    property bool enabled: true
    property string city: ""            // user override; "" = automatic
    property bool fahrenheit: false

    // Resolved location
    property real lat: NaN
    property real lon: NaN
    property string place: ""

    // Current conditions
    property bool ready: false
    property real temp: NaN
    property real feelsLike: NaN
    property int code: -1
    property bool isDay: true
    property int humidity: -1
    property real wind: NaN
    property var daily: []              // [{ date, code, max, min }]
    property string error: ""

    readonly property string unit: fahrenheit ? "°F" : "°C"
    readonly property string icon: iconFor(code, isDay)
    readonly property string summary: describe(code)

    function describe(c) {
        if (c === 0) return i18n("Clear");
        if (c === 1) return i18n("Mostly clear");
        if (c === 2) return i18n("Partly cloudy");
        if (c === 3) return i18n("Overcast");
        if (c === 45 || c === 48) return i18n("Fog");
        if (c >= 51 && c <= 57) return i18n("Drizzle");
        if (c >= 61 && c <= 67) return c >= 66 ? i18n("Freezing rain") : i18n("Rain");
        if (c >= 71 && c <= 77) return i18n("Snow");
        if (c >= 80 && c <= 82) return i18n("Showers");
        if (c === 85 || c === 86) return i18n("Snow showers");
        if (c >= 95) return i18n("Thunderstorm");
        return "";
    }

    function iconFor(c, day) {
        var n = day ? "" : "-night";
        if (c === 0) return "weather-clear" + n;
        if (c === 1 || c === 2) return "weather-few-clouds" + n;
        if (c === 3) return "weather-overcast";
        if (c === 45 || c === 48) return "weather-fog";
        if (c >= 51 && c <= 55) return "weather-showers-scattered" + n;
        if (c === 56 || c === 57 || c === 66 || c === 67) return "weather-freezing-rain";
        if (c >= 61 && c <= 65) return "weather-showers";
        if (c >= 71 && c <= 77) return "weather-snow";
        if (c >= 80 && c <= 82) return "weather-showers-scattered" + n;
        if (c === 85 || c === 86) return "weather-snow-scattered";
        if (c >= 95) return "weather-storm";
        return "weather-none-available";
    }

    // Accent colors the clock tile glows with, by sky.
    function mood(c, day) {
        if (!day) return ["#818cf8", "#312e81"];
        if (c === 0 || c === 1) return ["#fbbf24", "#f97316"];
        if (c === 2 || c === 3 || c === 45 || c === 48) return ["#cbd5e1", "#64748b"];
        if (c >= 71 && c <= 77 || c === 85 || c === 86) return ["#e0f2fe", "#93c5fd"];
        if (c >= 95) return ["#a78bfa", "#facc15"];
        if (c >= 51) return ["#38bdf8", "#1d4ed8"];
        return ["#c7d2fe", "#818cf8"];
    }

    function get(url, onDone) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            var data = null;
            if (xhr.status === 200) {
                try { data = JSON.parse(xhr.responseText); } catch (e) {}
            }
            try { onDone(data); } catch (e) { console.warn("Solidget weather:", e); }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function locate() {
        if (!enabled) return;
        error = "";
        if (city.trim() !== "") {
            get("https://geocoding-api.open-meteo.com/v1/search?count=1&name=" + encodeURIComponent(city.trim()), function (d) {
                var r = d && d.results && d.results[0];
                if (!r) { error = i18n("City not found"); ready = false; return; }
                setLocation(r.latitude, r.longitude, r.name);
            });
            return;
        }
        get("https://ipwho.is/", function (d) {
            if (d && d.success && d.latitude !== undefined) {
                setLocation(d.latitude, d.longitude, d.city || "");
                return;
            }
            get("https://get.geojs.io/v1/ip/geo.json", function (g) {
                if (g && g.latitude) setLocation(parseFloat(g.latitude), parseFloat(g.longitude), g.city || "");
                else error = i18n("Location unavailable");
            });
        });
    }

    function setLocation(la, lo, name) {
        lat = la;
        lon = lo;
        place = name;
        refresh();
    }

    function refresh() {
        if (!enabled || isNaN(lat)) return;
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat.toFixed(3) + "&longitude=" + lon.toFixed(3)
            + "&current=temperature_2m,apparent_temperature,weather_code,is_day,relative_humidity_2m,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=5&timezone=auto"
            + (fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");
        get(url, function (d) {
            if (!d || !d.current) { error = i18n("Weather unavailable"); return; }
            temp = d.current.temperature_2m;
            feelsLike = d.current.apparent_temperature;
            code = d.current.weather_code;
            isDay = d.current.is_day === 1;
            humidity = d.current.relative_humidity_2m;
            wind = d.current.wind_speed_10m;
            var days = [];
            for (var i = 0; d.daily && i < d.daily.time.length; i++)
                days.push({ date: d.daily.time[i], code: d.daily.weather_code[i],
                            max: d.daily.temperature_2m_max[i], min: d.daily.temperature_2m_min[i] });
            daily = days;
            error = "";
            ready = true;
        });
    }

    // callLater coalesces the burst of changes while config loads.
    onCityChanged: { lat = NaN; ready = false; Qt.callLater(locate); }
    onFahrenheitChanged: Qt.callLater(refresh)
    onEnabledChanged: if (enabled) Qt.callLater(locate)

    // Every 15 minutes; retry sooner while offline or not located yet.
    property Timer timer: Timer {
        interval: weather.ready ? 15 * 60 * 1000 : 2 * 60 * 1000
        running: weather.enabled
        repeat: true
        onTriggered: isNaN(weather.lat) ? weather.locate() : weather.refresh()
    }
    Component.onCompleted: Qt.callLater(locate)
}
