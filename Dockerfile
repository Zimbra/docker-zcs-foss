FROM ubuntu:16.04

# Install Basic Packages
RUN apt-get update && \
    apt-get install -y \
    curl \
    dnsutils \
    gettext \
    linux-tools-common \
    net-tools \
    rsyslog \
    software-properties-common \
    vim \
    wget

RUN groupadd -r -g 1000 zimbra && \
    useradd -r -g zimbra -u 1000 -b /opt -s /bin/bash zimbra
RUN curl -s -k -o /tmp/zcs.tgz 'https://files.zimbra.com.s3.amazonaws.com/downloads/8.8.3_GA/zcs-8.8.3_GA_1872.UBUNTU16_64.20170905143325.tgz'
RUN mkdir -p /tmp/release && \
    tar xzvf /tmp/zcs.tgz -C /tmp/release --strip-components=1 && \
    rm /tmp/zcs.tgz
# Trick build into skipping resolvconf as docker overrides for DNS
# This is currently required by our installer script. Hopefully be
# fixed soon.  The `zimbra-os-requirements` packages depends
# on the `resolvconf` package, and configuration of that is what
# is breaking install.sh
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections
COPY ./slash-zimbra /zimbra
WORKDIR /tmp/release
RUN sed -i.bak 's/checkRequired/# checkRequired/' install.sh && \
    ./install.sh -s -x --skip-upgrade-check < /zimbra/software-install-responses
RUN rm -rf /tmp/release
EXPOSE 22 25 80 110 143 443 465 587 993 995 7071 8443
