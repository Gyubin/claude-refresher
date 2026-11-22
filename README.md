# Claude Refresher

매일 정해진 시각에 Claude Code를 호출해 사용량 limit window의 시작 시각을 고정하는 스크립트

## 실행 방법

```bash
./refresher.sh
```

스크립트는 종료하지 않고 계속 실행되므로 `tmux`·`nohup` 등으로 띄워 두는 것을 권장합니다.

## 동작 방식

KST(한국 시간) 기준으로 다음 시각에 Claude를 호출합니다:
- 07:01
- 12:02
- 17:03
- 22:04

호출 시각을 고정해 사용량 limit window의 시작 시각을 매일 같게 맞추는 것이 목적입니다.
window는 첫 호출로부터 5시간이므로, 슬롯마다 1분씩 뒤로 밀어 직전 window가 확실히
리셋된 뒤에 호출되도록 했습니다. 밤 22:04 호출의 window는 03:04에 끝나므로
다음날 아침은 다시 07:01로 정렬됩니다.

스크립트를 켜는 시각은 슬롯과 무관하므로, 시작 시에는 프롬프트를 보내지 않습니다.
대신 `claude --version`으로 CLI 가용 여부만 확인하고(window를 소모하지 않음) 첫 슬롯까지
대기합니다. CLI를 실행할 수 없으면 즉시 종료합니다.

## 토큰 사용 최소화

호출의 목적은 window를 여는 것뿐이므로, 사용량을 최대한 적게 쓰도록 호출합니다:
- 모델: `claude-haiku-5-5`
- 프롬프트: `Say only: ok`, 시스템 프롬프트: `Answer with one word.`
- `/tmp`에서 실행해 프로젝트 컨텍스트(CLAUDE.md 등)를 읽지 않음
- `--setting-sources ""`, `--tools ""`, `--strict-mcp-config`로 설정·도구·MCP 서버를 모두 제외
- `MAX_THINKING_TOKENS=0`, `--max-turns 1`로 thinking과 추가 턴을 차단

이렇게 하면 호출당 입력 토큰이 약 25k에서 약 2.5k로 줄어듭니다.
모델이나 프롬프트를 바꾸려면 `refresher.sh`의 `model`·`prompt` 변수를 수정하세요.

## 출력

각 호출의 결과를 한 줄로 요약해 출력하고, 이어서 다음 호출 예정 시각을 출력합니다.

```
Claude result: ok (model=claude-haiku-5-5, in=2804, out=4, cost=$0.0005626)
```

요약에는 `jq`가 필요합니다. `jq`가 없거나 응답이 JSON이 아니면 응답 원문을 그대로 출력합니다.

## 요구사항

- `claude` CLI가 설치되어 있고 로그인되어 있어야 합니다
- Bash 쉘 환경 (Linux GNU `date`와 macOS BSD `date` 모두 지원)
