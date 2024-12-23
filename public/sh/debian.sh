#!/bin/bash

# 指定项目名称（可以根据需要修改）
PROJECT="debian"

# 定义文件路径
RSYNC_JSON="rsync.json"
SYNC_LOG="sync.log"

# 获取当前时间戳
get_current_time() {
    echo $(date +"%Y-%m-%d %H:%M:%S %z")
}

get_current_timestamp() {
    echo $(date +%s)
}

# 获取某个时间戳加上 N 小时后的时间
add_hours() {
    local base_time=$1
    local hours=$2
    echo $(date -d "@$base_time + $hours hours" +"%Y-%m-%d %H:%M:%S %z")
}

add_days() {
    local base_time=$1
    local days=$2
    echo $(date -d "@$base_time + $days days" +"%Y-%m-%d %H:%M:%S %z")
}

# 同步文件夹的功能
sync_folders() {
    # 使用 rsync 同步文件夹
    echo "Starting rsync synchronization for project: $PROJECT"

    # 示例同步命令（根据实际需要修改）
    rsync -avz --progress /source/dir/ /destination/dir/
    
    # 检查 rsync 是否成功
    if [ $? -eq 0 ]; then
        echo "rsync completed successfully for project: $PROJECT."
        return 0
    else
        echo "rsync failed for project: $PROJECT."
        return 1
    fi
}

# 更新 JSON 文件中的状态
update_json_status() {
    local status=$1
    local current_time=$(get_current_time)
    local current_timestamp=$(get_current_timestamp)

    # 如果 rsync.json 文件不存在，创建它
    if [ ! -f "$RSYNC_JSON" ]; then
        echo "Creating rsync.json file."
        echo "[]" > "$RSYNC_JSON"
    fi

    # 检查是否包含指定项目的条目
    if ! jq --arg project "$PROJECT" '. | map(select(.name == $project)) | length' "$RSYNC_JSON" | grep -q '^0$'; then
        # 如果有项目条目，更新它
        jq --arg project "$PROJECT" --arg status "$status" --arg last_started "$current_time" --arg last_started_ts "$current_timestamp" \
           '. |= map(if .name == $project then .status = $status | .last_started = $last_started | .last_started_ts = ($last_started_ts | tonumber) else . end)' "$RSYNC_JSON" > tmp.json && mv tmp.json "$RSYNC_JSON"
    else
        # 如果没有项目条目，添加一个新条目
        jq --arg project "$PROJECT" --arg status "$status" --arg current_time "$current_time" --arg current_timestamp "$current_timestamp" \
           '. += [{"name": $project, "status": $status, "last_update": $current_time, "last_update_ts": ($current_timestamp | tonumber), "last_started": $current_time, "last_started_ts": ($current_timestamp | tonumber), "last_ended": "0001-01-01 00:00:00 +0000", "last_ended_ts": -62135596800, "next_schedule": "0001-01-01 00:00:00 +0000", "next_schedule_ts": -62135596800, "upstream": "rsync://rsync3.jp.NetBSD.org/pub/pkgsrc/", "size": "2.70T"}]' "$RSYNC_JSON" > tmp.json && mv tmp.json "$RSYNC_JSON"
    fi
}

# 更新 JSON 文件中的时间字段
update_json_time_fields() {
    local last_started=$1
    local last_started_ts=$2
    local last_ended
    local last_ended_ts
    local next_schedule
    local next_schedule_ts

    # 计算结束时间
    last_ended=$(add_hours "$last_started_ts" 1)
    last_ended_ts=$(date -d "$last_ended" +%s)

    # 计算 next_schedule
    next_schedule=$(add_days "$last_started_ts" 2)
    next_schedule_ts=$(date -d "$next_schedule" +%s)

    # 修改 JSON 中的相关字段
    jq --arg project "$PROJECT" --arg last_update "$last_started" --arg last_update_ts "$last_started_ts" \
       --arg last_started "$last_started" --arg last_started_ts "$last_started_ts" \
       --arg last_ended "$last_ended" --arg last_ended_ts "$last_ended_ts" \
       --arg next_schedule "$next_schedule" --arg next_schedule_ts "$next_schedule_ts" \
       '. |= map(if .name == $project then .last_update = $last_update | .last_update_ts = ($last_update_ts | tonumber) | .last_started = $last_started | .last_started_ts = ($last_started_ts | tonumber) | .last_ended = $last_ended | .last_ended_ts = ($last_ended_ts | tonumber) | .next_schedule = $next_schedule | .next_schedule_ts = ($next_schedule_ts | tonumber) else . end)' "$RSYNC_JSON" > tmp.json && mv tmp.json "$RSYNC_JSON"
}

# 执行同步
update_json_status "syncing"

# 开始同步
if sync_folders; then
    # 如果同步成功
    update_json_time_fields "$(get_current_time)" "$(get_current_timestamp)"
    update_json_status "success"
else
    # 如果同步失败
    update_json_time_fields "$(get_current_time)" "$(get_current_timestamp)"
    update_json_status "failed"
fi
