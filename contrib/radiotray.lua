local io = { popen = io.popen }
local setmetatable = setmetatable

local current_radio_key = "getCurrentRadio"
local current_song_key = "getCurrentMetaData"
local radio_pattern = "\"(.*)%s?[%(]+(.*)[%)]+\""
local radio_pattern_playing = "\"(.*)\""
local song_pattern = "\"(.*)%s?-%s?(.*)\""

local radiotray = {}

local function is_empty(s)
    return s == nil or s == ""
end

local function dbus_session_send(key)
    local method = "dbus-send --session --print-reply --type=method_call --dest=net.sourceforge.radiotray /net/sourceforge/radiotray net.sourceforge.radiotray." .. key
    return io.popen(method)
end

local function get_info(status, f, pattern)
    local info = {}

    if status then
        local i = 0
        for line in f:lines() do
            i = i + 1
            if i == 2 then
                if pattern == radio_pattern then
                    local radio, state = line:match(pattern)
                    if is_empty(radio) then
                        radio, state = line:match(radio_pattern_playing)
                    end
                    info["{Radio}"] = radio
                    info["{State}"] = state
                else
                    local artist, song = line:match(pattern)
                    info["{Artist}"] = artist
                    info["{Song}"] = song
                end
            end
        end
    end
    f:close()

    return info
end

local function get_radio()
    local status, f = pcall(dbus_session_send, current_radio_key)
    return get_info(status, f, radio_pattern)
end

local function get_song()
    local status, f = pcall(dbus_session_send, current_song_key)
    return get_info(status, f, song_pattern)
end

local function worker(format, warg)
    local metatable = {
        ["{State}"] = "Stop",
        ["{Radio}"] = "N/A",
        ["{Artist}"] = "N/A",
        ["{Song}"] = "N/A"
    }

    radio_info = get_radio()
    song_info = get_song()

    if is_empty(radio_info["{State}"]) == false then
        metatable["{State}"] = radio_info["{State}"]
    end
    if is_empty(radio_info["{Radio}"]) == false then
        metatable["{Radio}"] = radio_info["{Radio}"]
        if is_empty(radio_info["{State}"]) then
            metatable["{State}"] = "Playing"
        end
    end
    if is_empty(song_info["{Artist}"]) == false then
        metatable["{Artist}"] = song_info["{Artist}"]
    end
    if is_empty(song_info["{Song}"]) == false then
        metatable["{Song}"] = song_info["{Song}"]
    end

    return metatable
end

return setmetatable(radiotray, { __call = function(_, ...) return worker(...) end })
