FROM postgres:17-bookworm AS base

### BUILDER
###
FROM base AS builder
ARG POSTGRES_VERSION=17
ARG BRANCH=main

# Update and add the dependencies for building pg_duckdb
RUN apt-get update -qq && \
    apt-get install -y \
    postgresql-server-dev-${POSTGRES_VERSION} \
    build-essential libreadline-dev zlib1g-dev flex bison libxml2-dev libxslt-dev \
    libssl-dev libxml2-utils xsltproc pkg-config libc++-dev libc++abi-dev libglib2.0-dev \
    libtinfo-dev cmake libstdc++-12-dev liblz4-dev ccache ninja-build git && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

ENV PATH="/usr/lib/ccache:${PATH}"
ENV CCACHE_DIR=/ccache

# Clone the pg_duckdb repository
RUN git clone \
  --jobs $(nproc) \
   https://github.com/duckdb/pg_duckdb

WORKDIR /build/pg_duckdb

RUN git checkout ${BRANCH}
RUN git submodule update --init --recursive --jobs $(nproc)

# permissions so we can run as `postgres` user (uid=999, gid=999)
RUN mkdir -p /out
RUN chown -R postgres:postgres . /usr/lib/postgresql /usr/share/postgresql /out
USER postgres

# build
# mount ccache to speed up builds make postgres a non-root user
# -j$(nproc) to use all cores
RUN --mount=type=cache,target=/ccache/,uid=999,gid=999 make -j$(nproc)
# install into location specified by pg_config for tests
RUN make install
# install into /out for packaging
RUN DESTDIR=/out make install

### CHECKER
###
FROM builder AS checker

USER postgres
RUN make installcheck

### OUTPUT
###
# This creates a usable postgres image but without the stuff added for building
FROM base AS output
# move build from /out to root
COPY --from=builder /out /

# # stuff
COPY custom-postgresql.conf /etc/postgresql/conf.d/custom-postgresql.conf

# Ensure file permissions are correct
RUN chown postgres:postgres /etc/postgresql/conf.d/custom-postgresql.conf && \
chmod 644 /etc/postgresql/conf.d/custom-postgresql.conf

# Append include directive to postgresql.conf
RUN echo "include_dir='/etc/postgresql/conf.d/custom-postgresql.conf'" >> /usr/share/postgresql/postgresql.conf.sample

# # Copy the init script to the entrypoint directory
COPY init-user-db.sh /docker-entrypoint-initdb.d/init-user-db.sh


