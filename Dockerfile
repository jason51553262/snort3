FROM python:3.11-slim-bookworm AS debian-slim-base

RUN apt-get update && \
    apt-get install -y wget openssh-client procps coreutils curl vim pkg-config gnupg2 lsb-release openssl iproute2 inetutils-traceroute net-tools && \
    pip3 install --upgrade pip && \
    pip3 install jinja2 && \
    rm -rf /var/lib/apt/lists/*

# Build stage
FROM debian-slim-base AS build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        bison \
        build-essential \
        checkinstall zlib1g-dev perl libfindbin-libs-perl \
        automake autoconf libtool pkg-config perl \
        ca-certificates \
        cmake \
        libz-dev libbz2-dev \
        libfl-dev \
        openssl \
        libssl-dev \
        libhyperscan-dev \
        libhyperscan5 \
        libluajit-5.1-dev \
        liblzma-dev \
        libpcap-dev \
        libssh-dev \
        libgoogle-perftools-dev \
        libhwloc-dev \
        uuid-dev \
        libsafec-dev \
        libjemalloc-dev \
        libc6-dev \
        autoconf \
        libtool \
        pkg-config \
        automake \
        tar \
        wget \
        git \
        check \
        zlib1g-dev \
        libmnl-dev \
        libnet1-dev \
        libunwind-dev \
        flex && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/*deb /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN mkdir /snort && mkdir -p /etc/snort/rules
WORKDIR /snort

# Install Libdaq
ENV DAQ_VERSION=3.0.19
RUN wget -nv https://github.com/snort3/libdaq/archive/refs/tags/v${DAQ_VERSION}.tar.gz && \
    tar -xf v${DAQ_VERSION}.tar.gz && \
    cd libdaq-${DAQ_VERSION} && \
    ./bootstrap && \
    ./configure --prefix=/usr && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf v${DAQ_VERSION}.tar.gz libdaq-${DAQ_VERSION}

# Install LibML
ENV LIBML_VERSION=2.0.0
RUN git clone --depth=1 https://github.com/snort3/libml.git && \
    cd libml && \
    ./configure.sh --prefix=/usr  && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf libml

# Install libdnet
RUN wget -q https://github.com/ofalk/libdnet/archive/refs/tags/libdnet-1.18.0.tar.gz && \
    tar -xzf libdnet-1.18.0.tar.gz && \
    cd libdnet-libdnet-1.18.0 && \
    ./configure --prefix=/usr && \
    make && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf libdnet-1.18.0.tar.gz libdnet-libdnet-1.18.0

# Install pcre
RUN wget -q https://github.com/PCRE2Project/pcre2/releases/download/pcre2-10.45/pcre2-10.45.tar.gz && \
    tar -xzf pcre2-10.45.tar.gz && \
    cd pcre2-10.45 && \
    ./configure --prefix=/usr \
                --enable-unicode \
                --enable-jit \
                --enable-pcre2-16 \
                --enable-pcre2-32 \
                --enable-pcre2grep-libz \
                --enable-pcre2grep-libbz2 && \
    make -j$(nproc) && \
    make install && \
    ln -sf /usr/lib/pkgconfig/libpcre2-8.pc /usr/lib/pkgconfig/libpcre2.pc && \
    cd .. && \
    rm -rf pcre2-10.45 pcre2-10.45.tar.gz && \
    ldconfig

# Install Snort
ENV SNORT_VERSION=3.7.3.0
RUN wget -nv https://github.com/snort3/snort3/archive/refs/tags/${SNORT_VERSION}.tar.gz && \
    tar -xf ${SNORT_VERSION}.tar.gz && \
    cd snort3-${SNORT_VERSION} && \
    ./configure_cmake.sh --help; \
    ./configure_cmake.sh --prefix=/usr --enable-tcmalloc --disable-docs \
        --enable-debug-msgs --enable-control-socket && \
    cd build && \
    make -j$(nproc) && \
    make install && \
    cd / && \
    rm -rf ${SNORT_VERSION}.tar.gz snort3-${SNORT_VERSION}

RUN ldd /usr/bin/snort | tee /tmp/snort-ldd-check && \
    if grep -q "not found" /tmp/snort-ldd-check; then \
        echo "ERROR: Missing libraries detected in Snort binary!" && exit 1; \
    else \
        echo "All Snort runtime dependencies are satisfied."; \
    fi

RUN ldconfig

# Runtime stage
FROM debian-slim-base

# Install runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
        tcpdump libdumbnet1 libhwloc15 libhyperscan5 libluajit-5.1-2 liblzma5 \
        libpcap0.8 libssh-4 zlib1g openssl libssl3 \
        libgoogle-perftools4 libnuma1 libunwind8 libuuid1 libsafec3 \
        libjemalloc2 libudev1 ca-certificates tar libunwind8 libnet1 libmnl0 && \
    apt-get clean && \
    rm -rf /var/cache/apt/archives/*deb /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy necessary files from build stage
COPY --from=build /usr/bin/snort /usr/bin/
COPY --from=build /usr/etc/snort /etc/snort/
COPY --from=build /usr/lib /usr/lib/
COPY --from=build /usr/include /usr/include/

COPY *.lua /etc/snort/
COPY version /app/version
COPY /docker-entrypoint.sh /
RUN chmod +x /docker-entrypoint.sh

# Symlink for libml version if needed
RUN ln -s /usr/lib/libml.so /usr/lib/libml.so.2

RUN ldconfig

# Final check: ensure all runtime dependencies are resolved
RUN ldd /usr/bin/snort | tee /tmp/snort-ldd-check && \
    if grep -q "not found" /tmp/snort-ldd-check; then \
        echo "Missing libraries detected!" && exit 1; \
    else \
        echo "All runtime dependencies are satisfied."; \
    fi

# Define a build argument for skipping the smoke test
ARG SKIP_TEST=false

# Smoke test
COPY /test/* /test/
RUN if [ "$SKIP_TEST" = "false" ]; then \
        echo "Running smoke test... 🚀"; \
        mkdir -p /test && \
        cd /test/ && ./smoke.test.sh || exit 1 \
    else \
        echo "Skipping smoke test. ❌"; \
    fi


ENTRYPOINT ["/docker-entrypoint.sh"]
