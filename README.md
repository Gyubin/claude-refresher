# Claude Refresher

매일 정해진 시간에 Claude Code를 호출하는 스크립트

## 실행 방법

```bash
./refresher.sh
```

## 동작 방식

KST(한국 시간) 기준으로 다음 시간에 Claude가 응원 메시지를 보냅니다:
- 07:01 - 아침 응원
- 12:01 - 점심 응원
- 17:01 - 저녁 응원
- 22:01 - 밤 응원

## 요구사항

- `claude` CLI가 설치되어 있어야 합니다
- Bash 쉘 환경
