# Taken from and modified to fit Ubuntu from older variant of
# https://github.com/docker-library/openjdk/
FROM artifacts.msap.io/mulesoft/core-paas-base-image-ubuntu:5.2.145 as base

# A few reasons for installing distribution-provided OpenJDK:
#
#  1. Oracle.  Licensing prevents us from redistributing the official JDK.
#
#  2. Compiling OpenJDK also requires the JDK to be installed, and it gets
#     really hairy.
#
#     For some sample build times, see Debian's buildd logs:
#       https://buildd.debian.org/status/logs.php?pkg=openjdk-11

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER root

# https://www.bouncycastle.org/fips-java/RELEASE_NOTES.md
ENV BC_FIPS_VERSION 1.0.2.4

RUN set -ex; \
    \
    # deal with slim variants not having man page directories (which causes "update-alternatives" to fail)
    if [ ! -d /usr/share/man/man1 ]; then \
    mkdir -p /usr/share/man/man1; \
    fi; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
    unzip \
    xz-utils \
    openjdk-11-jdk \
    ; \
    rm -rf /var/lib/apt/lists/*

# Add a wrapper to be able to turn on/off FIPS with env var FIPS_ENABLED
RUN mv /usr/bin/java /usr/bin/java.real
COPY assets/java /usr/bin

# Add utlity script to easily add certificates to the java ca keystore
COPY assets/add-cacert-to-java-keystore.sh /java/
# Entrypoint goes to / to match parent image
COPY assets/java-entrypoint.sh /

# Install Bouncycastle
COPY assets/java.fips.security /java/
COPY assets/java.policy /java/
ADD https://repo1.maven.org/maven2/org/bouncycastle/bc-fips/${BC_FIPS_VERSION}/bc-fips-${BC_FIPS_VERSION}.jar /java/bc-fips.jar

# Extra java.security configuration
COPY assets/java.security /java/

# Make cacerts available to the local app user by copying it
RUN cp /etc/ssl/certs/java/cacerts /java/ && chown app:app /java/cacerts

USER 2020
### TESTING STAGE STARTS HERE
FROM base as builder
USER 2020
COPY test/* /usr/src/app
RUN javac -verbose /usr/src/app/App.java -d /usr/src/app

FROM base as final
COPY --from=test /usr/src/app/test-results.txt /usr/test/test-results.txt
USER 2020
ENTRYPOINT ["/java-entrypoint.sh"]