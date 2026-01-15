# WordPress env_build

## 실행

```bash
docker compose up --build
```

- WordPress: `http://localhost:8080`
- 기본 관리자: `admin` / `admin1234`

## Apple Silicon(M1/M2) 참고

`docker-compose.yml`의 DB는 `mysql:5.7`(amd64 전용)이라서 `platform: linux/amd64`로 고정되어 있습니다.
