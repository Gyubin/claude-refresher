#!/bin/bash
readonly KST_OFFSET=$((9 * 3600))
target_hours=(7 12 17 22)

if date -u -d "@0" +%s >/dev/null 2>&1; then
    format_epoch_kst() {
        local ts=$1
        local fmt=${2:-"+%Y-%m-%d %H:%M:%S KST"}
        TZ=Asia/Seoul date -d "@$ts" "$fmt"
    }
else
    format_epoch_kst() {
        local ts=$1
        local fmt=${2:-"+%Y-%m-%d %H:%M:%S KST"}
        TZ=Asia/Seoul date -r "$ts" "$fmt"
    }
fi

next_scheduled_epoch() {
    local ts=$1
    local ts_kst seconds_since_midnight day_start_kst target_hour candidate_kst

    ts_kst=$((ts + KST_OFFSET))
    seconds_since_midnight=$((ts_kst % 86400))
    day_start_kst=$((ts_kst - seconds_since_midnight))

    for target_hour in "${target_hours[@]}"; do
        candidate_kst=$((day_start_kst + target_hour * 3600 + 60))
        if [ "$ts_kst" -lt "$candidate_kst" ]; then
            echo $((candidate_kst - KST_OFFSET))
            return
        fi
    done

    target_hour=${target_hours[0]}
    candidate_kst=$((day_start_kst + 86400 + target_hour * 3600 + 60))
    echo $((candidate_kst - KST_OFFSET))
}

echo "시작할 때 한 번 호출"
prompt="ssh 약자를 한 문장으로 짧게:"
model="claude-haiku-4-5-20251001"
response=$(claude -p "$prompt" )
response=$(claude -p "$prompt" --model "$model")
echo "Claude says: $response"
echo "====================="

next_call_epoch=$(next_scheduled_epoch "$(date -u +%s)")

while true; do
    now=$(date -u +%s)

    if [ "$now" -lt "$next_call_epoch" ]; then
        wait_seconds=$((next_call_epoch - now))
        next_window=$(format_epoch_kst "$next_call_epoch")
        echo "Waiting $wait_seconds seconds until next run at $next_window..."
        sleep "$wait_seconds"
        continue
    fi

    echo "Asking Claude: $prompt"
    response=$(claude -p "$prompt" --model "$model")
    echo "Claude says: $response"
    echo "====================="

    now=$(date -u +%s)
    next_call_epoch=$(next_scheduled_epoch "$now")
    scheduled_time=$(format_epoch_kst "$next_call_epoch")
    echo "Next claude call scheduled for $scheduled_time"
done
