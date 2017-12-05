#!/bin/bash

export GOOS=linux
export GOARCH=arm
export GOARM=7
export GOPATH=/tmp/${NAME}
export CGO_ENABLED=0

TMP_DIR=${GOPATH}/src/github.com/nsqio/nsq
BUILD_DIR=${TMP_DIR}/build

# Clone nsqio/nsq
git clone ${REPO_URL} ${TMP_DIR}
# Copy own Dockerfile into repo
cp Dockerfile ${TMP_DIR}

# Get dependencies
cd ${TMP_DIR}
wget -O ${TMP_DIR}/dep https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64
chmod +x ${TMP_DIR}/dep
${TMP_DIR}/dep ensure

# Compile for ARM
make -C ${TMP_DIR} DESTDIR=/opt PREFIX=/nsq GOFLAGS='-ldflags="-s -w"'

# Build docker image
if [ $(git describe --tags --abbrev=0) ]; then
    export VERSION=$(git describe --tags --abbrev=0);
fi
docker build --pull --cache-from ${DOCKER_USER}/${NAME}:${VERSION} --build-arg VCS_URL=${REPO_URL} --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` --build-arg VCS_REF=${TRAVIS_COMMIT} --build-arg VERSION=${VERSION} -t "${DOCKER_USER}/${NAME}:${VERSION}" -f ${TMP_DIR}/Dockerfile${DOTARCH} ${TMP_DIR}

# Check image
docker inspect ${DOCKER_USER}/${NAME}:${VERSION}

# Push image
docker login -u ${DOCKER_USER} -p ${DOCKER_PASS} ${DOCKER_REPO}
docker push "${DOCKER_USER}/${NAME}:${VERSION}"

# Create multiarch manifest
wget https://github.com/estesp/manifest-tool/releases/download/v0.7.0/manifest-tool-linux-amd64
chmod +x manifest-tool-linux-amd64
cat > ${TMP_DIR}/${VERSION}-multiarch.yml << EOF
image: r3r57/nsq-multiarch:${VERSION}
manifests:
  - image: nsqio/nsq:${VERSION}
    platform:
      architecture: amd64
      os: linux
  - image: r3r57/nsq-for-arm:${VERSION}
    platform:
      architecture: arm
      os: linux
EOF
./manifest-tool-linux-amd64 push from-spec ${TMP_DIR}/${VERSION}-multiarch.yml
cat > ${TMP_DIR}/latest-multiarch.yml << EOF
image: r3r57/nsq-multiarch:${VERSION}
manifests:
  - image: nsqio/nsq:${VERSION}
    platform:
      architecture: amd64
      os: linux
  - image: r3r57/nsq-for-arm:${VERSION}
    platform:
      architecture: arm
      os: linux
EOF
./manifest-tool-linux-amd64 push from-spec ${TMP_DIR}/latest-multiarch.yml

# Clean
rm -rf ${TMP_DIR}