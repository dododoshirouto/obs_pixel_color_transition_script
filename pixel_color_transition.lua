
obs = obslua

-- ▼ 設定変数
source_name     = ""
pixel_x         = 0
pixel_y         = 0
target_r        = 255
target_g        = 255
target_b        = 255
threshold       = 10
target_scene    = ""
transition_type = "Fade"
trigger_mode    = "match" -- "match" or "mismatch"

-- ▼ UI定義
function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_text(props, "source_name", "監視ソース名", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "pixel_x", "X座標", 0, 3840, 1)
    obs.obs_properties_add_int(props, "pixel_y", "Y座標", 0, 2160, 1)

    obs.obs_properties_add_int_slider(props, "target_r", "赤 (R)", 0, 255, 1)
    obs.obs_properties_add_int_slider(props, "target_g", "緑 (G)", 0, 255, 1)
    obs.obs_properties_add_int_slider(props, "target_b", "青 (B)", 0, 255, 1)

    obs.obs_properties_add_int_slider(props, "threshold", "許容しきい値", 0, 100, 1)

    obs.obs_properties_add_text(props, "target_scene", "切り替え先シーン", obs.OBS_TEXT_DEFAULT)

    local list = obs.obs_properties_add_list(props, "transition_type", "トランジション", obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING)
    obs.obs_property_list_add_string(list, "Fade", "Fade")
    obs.obs_property_list_add_string(list, "Cut", "Cut")
    obs.obs_property_list_add_string(list, "Swipe", "Swipe")

    local trigger_list = obs.obs_properties_add_list(
        props, "trigger_mode", "切り替えトリガー",
        obs.OBS_COMBO_TYPE_LIST, obs.OBS_COMBO_FORMAT_STRING
    )
    obs.obs_property_list_add_string(trigger_list, "match", "色が一致したとき")
    obs.obs_property_list_add_string(trigger_list, "mismatch", "色が一致しなくなったとき")

    return props
end

-- ▼ UI入力反映
function script_update(settings)
    source_name     = obs.obs_data_get_string(settings, "source_name")
    pixel_x         = obs.obs_data_get_int(settings, "pixel_x")
    pixel_y         = obs.obs_data_get_int(settings, "pixel_y")
    target_r        = obs.obs_data_get_int(settings, "target_r")
    target_g        = obs.obs_data_get_int(settings, "target_g")
    target_b        = obs.obs_data_get_int(settings, "target_b")
    threshold       = obs.obs_data_get_int(settings, "threshold")
    target_scene    = obs.obs_data_get_string(settings, "target_scene")
    transition_type = obs.obs_data_get_string(settings, "transition_type")
    trigger_mode    = obs.obs_data_get_string(settings, "trigger_mode")
end

-- ▼ 色差
function color_distance(r1, g1, b1, r2, g2, b2)
    return math.sqrt((r1 - r2)^2 + (g1 - g2)^2 + (b1 - b2)^2)
end

-- ▼ シーン切り替え
function switch_scene()
    local scene = obs.obs_get_scene_by_name(target_scene)
    if scene ~= nil then
        obs.obs_frontend_set_current_scene(scene)
        obs.obs_source_release(scene)
    end
end

-- ▼ メイン監視ループ（擬似色取得）
local last_switch_time = 0

function script_tick(seconds)
    local now = os.time()

    -- この部分はダミー色（R,G,B）を交互に変化させて試験動作させる
    local dummy_r = (now % 20 < 10) and 255 or 0
    local dummy_g = (now % 20 < 10) and 255 or 0
    local dummy_b = (now % 20 < 10) and 255 or 0

    local diff = color_distance(dummy_r, dummy_g, dummy_b, target_r, target_g, target_b)

    if (trigger_mode == "match" and diff <= threshold) or
       (trigger_mode == "mismatch" and diff > threshold) then
        if now ~= last_switch_time then
            switch_scene()
            last_switch_time = now
        end
    end
end
