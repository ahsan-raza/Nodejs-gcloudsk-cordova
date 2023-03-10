FROM jangrewe/gitlab-ci-android AS android
RUN sdkmanager "build-tools;30.0.3"

FROM node:lts AS node
RUN npm install -g cordova

FROM google/cloud-sdk:slim AS cloud


FROM eclipse-temurin:11-jdk-jammy
COPY --from=cloud . .
COPY --from=android . .
COPY --from=node . .
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/sdk/cmdline-tools/latest/bin:/sdk/build-tools
ENV ANDROID_SDK_ROOT=/sdk
ENV ANDROID_HOME=/sdk

CMD ["gradle"]

ENV GRADLE_HOME /opt/gradle

RUN set -o nounset \
    && groupadd --system --gid 1001 gradle \
    && useradd --system --gid gradle --uid 1001 --shell /bin/bash --create-home gradle \
    && mkdir /home/gradle/.gradle \
    && chown --recursive gradle:gradle /home/gradle \
    \
    && echo "Symlinking root Gradle cache to gradle Gradle cache" \
    && ln --symbolic /home/gradle/.gradle /root/.gradle

VOLUME /home/gradle/.gradle

WORKDIR /home/gradle

RUN set -o errexit -o nounset \
    && apt-get update \
    && apt-get install --yes --no-install-recommends \
        unzip \
        wget \
        \
        bzr \
        git \
        git-lfs \
        mercurial \
        openssh-client \
        subversion \
    && rm --recursive --force /var/lib/apt/lists/* \
    \
    && echo "Testing VCSes" \
    && which bzr \
    && which git \
    && which git-lfs \
    && which hg \
    && which svn

ENV GRADLE_VERSION 8.0.1
ARG GRADLE_DOWNLOAD_SHA256=1b6b558be93f29438d3df94b7dfee02e794b94d9aca4611a92cdb79b6b88e909
RUN set -o errexit -o nounset \
    && echo "Downloading Gradle" \
    && wget --no-verbose --output-document=gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    \
    && echo "Checking download hash" \
    && echo "${GRADLE_DOWNLOAD_SHA256} *gradle.zip" | sha256sum --check - \
    \
    && echo "Installing Gradle" \
    && unzip gradle.zip \
    && rm gradle.zip \
    && mv "gradle-${GRADLE_VERSION}" "${GRADLE_HOME}/" \
    && ln --symbolic "${GRADLE_HOME}/bin/gradle" /usr/bin/gradle \
    \
    && echo "Testing Gradle installation" \
    && gradle --version
RUN printenv PATH
