FROM alpine:latest

ARG ARIANG_VERSION
ARG BUILD_DATE
ARG VCS_REF

# Set environment variables
ENV ARIA2RPCPORT=6800
ENV ARIANGPORT=6888

LABEL maintainer="almir1904" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.name="aria2-ariang" \
    org.label-schema.description="Aria2 downloader and AriaNg webui Docker image based on Alpine Linux" \
    org.label-schema.version=$ARIANG_VERSION \
    org.label-schema.url="https://github.com/almir1904/ariang-docker" \
    org.label-schema.license="MIT" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url="https://github.com/almir1904/ariang-docker" \
    org.label-schema.vcs-type="Git" \
    org.label-schema.vendor="almir1904" \
    org.label-schema.schema-version="1.0"

# Install required packages and clean up
RUN apk --no-cache add darkhttpd aria2 curl su-exec && \
    rm -rf /var/cache/apk/*

# AriaNG
WORKDIR /usr/local/www/ariang

# Create directories for Aria2 data and configuration
RUN mkdir -p /aria2/data /aria2/conf

# Download and install AriaNg
RUN wget --no-check-certificate https://github.com/mayswind/AriaNg/releases/download/${ARIANG_VERSION}/AriaNg-${ARIANG_VERSION}.zip \
    -O ariang.zip \
    && unzip ariang.zip \
    && rm ariang.zip \
    && chmod -R 755 ./

# Copy configuration files and entrypoint script
COPY aria2.conf /aria2/conf/aria2.conf
COPY docker-entrypoint.sh /aria2/docker-entrypoint.sh
COPY healthcheck.sh /aria2/healthcheck.sh

# Make the entrypoint script executable
RUN chmod +x /aria2/docker-entrypoint.sh
RUN chmod +x /aria2/healthcheck.sh

# Expose ports 6800 for Aria2 RPC and 6888 for AriaNg
EXPOSE 6800 6888

HEALTHCHECK --interval=30s --timeout=10s --retries=3 CMD /bin/sh /aria2/healthcheck.sh

# Define the entrypoint
ENTRYPOINT ["/aria2/docker-entrypoint.sh"]

# Specify the default command
CMD ["--conf-path=/aria2/conf/aria2.conf"]
