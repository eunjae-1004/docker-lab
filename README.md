# Docker Lab 설치 안내

Windows PC에서 n8n, PostgreSQL, pgAdmin을 실행하는 설치 패키지입니다.
각 PC에서 독립적으로 실행하며 데이터도 해당 PC에 저장됩니다.

## 1. 준비

1. Docker Desktop을 설치합니다: https://www.docker.com/products/docker-desktop/
2. 설치 과정에서 WSL 2 사용 안내가 나오면 완료하고, 필요하면 PC를 재시작합니다.
3. Docker Desktop을 실행하고 Linux containers 모드가 준비될 때까지 기다립니다.
4. 배포 ZIP을 다운로드한 뒤 **압축을 풉니다**. 폴더를 `D:\`에 둘 필요는 없습니다. 바탕 화면, `C:\apps\docker-lab`, 다른 드라이브처럼 쓰기 가능한 위치면 됩니다.

스크립트는 자신이 놓인 폴더에서 `compose.yaml`과 `.env`를 찾습니다. 실행 전에 특정 드라이브로 이동하지 않아도 됩니다.
Docker 스택 이름은 폴더 경로와 상관없이 `docker-lab`입니다. 같은 PC에서 폴더를 옮겨도 기존 데이터 볼륨을 그대로 사용합니다.

Docker Desktop 사용 조건은 설치 전 해당 조직에서 확인하세요.

## 2. 설치와 접속

1. `install.bat`을 더블클릭합니다. 인터넷 연결이 필요하며 첫 실행에는 이미지 다운로드 시간이 걸립니다.
2. 설치가 완료된 뒤 http://localhost:5678 에 접속합니다. 준비 중이면 잠시 후 새로고침합니다.
3. n8n 첫 화면에서 소유자 계정을 만듭니다. 이 계정은 DB 계정이나 pgAdmin 계정과 별개입니다.
4. pgAdmin은 http://localhost:5050 에서 사용합니다. 로그인 이메일과 비밀번호는 설치 폴더의 `.env`에서 확인합니다.

최초 설치 시 `.env`가 자동 생성됩니다. 기존 `.env`는 덮어쓰지 않습니다.
다른 PC에 배포할 때는 자신의 `.env`를 함께 보내지 마세요.
서비스는 해당 PC의 localhost에서만 접속할 수 있습니다.

## 3. 실행과 중지

- `start.bat`: 설치한 서비스를 다시 실행합니다. Docker Desktop을 먼저 실행하세요.
- `stop.bat`: 서비스를 중지합니다. 데이터는 유지됩니다.
- 설치 오류 후에는 문제를 해결한 뒤 `install.bat`을 다시 실행할 수 있습니다.

pgAdmin에서 PostgreSQL 서버를 추가할 때 호스트는 `postgres`, 포트는 `5432`를 사용합니다.
사용자, 비밀번호, DB 이름은 `.env`의 POSTGRES 항목에서 확인합니다.

## 4. 문제가 생기면

설치 폴더로 이동한 뒤 PowerShell 또는 터미널을 열어 확인합니다. 폴더 위치는 `D:\`가 아니어도 됩니다.

```powershell
docker compose ps
docker compose logs --tail 100
```

- Docker 연결 오류: Docker Desktop이 실행 중이고 Linux containers 모드인지 확인합니다.
- 포트 충돌: `docker compose stop` 후 `.env`의 `N8N_PORT` 또는 `POSTGRES_PORT`를 변경하고 다시 실행합니다.
- 5050 포트 충돌: `compose.yaml`에서 `127.0.0.1:5050:80`의 5050을 변경합니다.
- 기존 데이터가 있다면 POSTGRES 비밀번호와 N8N_ENCRYPTION_KEY를 임의로 변경하지 마세요.

## 5. 데이터 보관

데이터는 Docker 볼륨에 저장됩니다. 설치 폴더를 복사하는 것만으로 데이터가 백업되지는 않습니다.
`.env`의 암호화 키와 Docker 볼륨 데이터를 함께 보관해야 기존 n8n 자격 증명을 복구할 수 있습니다.
`docker compose down -v` 또는 Docker Desktop의 데이터 초기화는 저장 데이터를 삭제하므로 사용에 주의하세요.
이 패키지는 백업 자동화를 포함하지 않습니다.

## 6. GitHub에 배포하기

배포자는 `dist/docker-lab-windows.zip`을 GitHub 저장소의 Releases에 첨부하면 됩니다.
사용자는 해당 ZIP을 받아 압축을 풀고 `install.bat`을 실행하면 됩니다.
소스 업로드 대상은 `compose.yaml`, `.env.example`, `.gitignore`, 배치 파일, `scripts/`, 이 안내서입니다.
실제 `.env`, 이미지 `.tar`, 데이터 백업은 업로드하지 마세요.
GitHub는 파일 배포에 사용하며 서비스는 각 사용자 PC에서 실행됩니다.

## 7. 오프라인 설치

인터넷 연결이 되는 Docker PC에서 이 compose가 사용하는 이미지들을 먼저 받습니다.

```powershell
docker compose pull
docker save -o docker-images.tar postgres:18 docker.n8n.io/n8nio/n8n:latest dpage/pgadmin4:latest
```

만들어진 `docker-images.tar`을 설치 패키지 폴더에 복사한 뒤 대상 PC에서 `install.bat`을 실행합니다.
대상 PC에는 Docker Desktop이 미리 설치되어 있어야 하며, 이미지의 CPU 아키텍처도 같아야 합니다.
설치 스크립트는 해당 파일이 있으면 이미지를 불러오고 추가 다운로드 없이 실행합니다.
현재 폴더에 있던 이미지 아카이브는 내용과 아키텍처를 검증하지 않았으므로 배포 ZIP에 포함하지 않았습니다.

현재 compose는 n8n과 pgAdmin에 latest 태그를 사용합니다. 여러 PC에서 동일 버전을 유지하려면
검증한 이미지 버전으로 태그를 고정한 뒤 배포하세요. 기존 설치에서 업데이트하기 전에는 데이터를 백업하세요.
