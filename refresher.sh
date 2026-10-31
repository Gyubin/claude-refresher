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
    local ts_kst seconds_since_midnight day_start_kst idx target_hour candidate_kst

    ts_kst=$((ts + KST_OFFSET))
    seconds_since_midnight=$((ts_kst % 86400))
    day_start_kst=$((ts_kst - seconds_since_midnight))

    # 슬롯마다 1분씩 뒤로 밀어 직전 호출의 5시간 window가 확실히 리셋된 뒤에 호출한다
    for idx in "${!target_hours[@]}"; do
        target_hour=${target_hours[idx]}
        candidate_kst=$((day_start_kst + target_hour * 3600 + (idx + 1) * 60))
        if [ "$ts_kst" -lt "$candidate_kst" ]; then
            echo $((candidate_kst - KST_OFFSET))
            return
        fi
    done

    target_hour=${target_hours[0]}
    candidate_kst=$((day_start_kst + 86400 + target_hour * 3600 + 60))
    echo $((candidate_kst - KST_OFFSET))
}

prompt="Say only: ok"
model="claude-haiku-4-5-20251001"

# 시작 시각은 슬롯과 무관하므로 여기서 프롬프트를 보내면 엉뚱한 시각에 limit window가
# 열려 다음 슬롯 호출을 삼킨다. window를 소모하지 않는 점검만 하고 첫 슬롯까지 기다린다.
if ! claude_version=$(claude --version 2>&1); then
    echo "claude CLI를 실행할 수 없습니다: $claude_version" >&2
    exit 1
fi
echo "claude CLI OK ($claude_version)"

next_call_epoch=$(next_scheduled_epoch "$(date -u +%s)")
echo "Next claude call scheduled for $(format_epoch_kst "$next_call_epoch")"

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
    # 빈 디렉터리·설정/도구/MCP/thinking 없이 호출해 입력·출력 토큰을 최소화한다
    response=$(cd /tmp && MAX_THINKING_TOKENS=0 claude -p "$prompt" --model "$model" \
        --max-turns 1 --tools "" --strict-mcp-config --setting-sources "" \
        --system-prompt "Answer with one word." --output-format json)
    echo "Claude result:"
    echo "$response"
    echo "====================="

    now=$(date -u +%s)
    next_call_epoch=$(next_scheduled_epoch "$now")
    scheduled_time=$(format_epoch_kst "$next_call_epoch")
    echo "Next claude call scheduled for $scheduled_time"
done
