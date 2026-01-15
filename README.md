# Red_team-Lab
## How to Build
```
$ docker compose up -d --build
```
The goal of this practice material is to read flags with root privileges in the following order: RECON → Leak admin pw → RCE → LPE → Flag.

# WordPress env_build

## 실행

```bash
docker compose up -d --build
```

- WordPress: `http://localhost:8080`

## Apple Silicon(M1/M2) 참고

`docker-compose.yml`의 DB는 `platform: linux/amd64`로 고정되어 있습니다.
