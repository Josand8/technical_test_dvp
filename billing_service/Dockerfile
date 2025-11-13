# Use a recent Ruby image
FROM ruby:3.4.3

# Install necessary libraries for Oracle (ruby-oci8/ActiveRecord Adapter)
# and standard build tools
RUN apt-get update -qq && apt-get install -y \
    build-essential \
    libaio1 \
    libpq-dev \
    nodejs \
    default-jre \
    tzdata \
    wget \
    unzip

# Download and install Oracle Instant Client (ARM64 version)
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-basic-linux.arm64-19.23.0.0.0dbru.zip -O /tmp/instantclient.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1923000/instantclient-sdk-linux.arm64-19.23.0.0.0dbru.zip -O /tmp/instantclient-sdk.zip && \
    unzip -o /tmp/instantclient.zip -d /opt/oracle && \
    unzip -o /tmp/instantclient-sdk.zip -d /opt/oracle && \
    rm /tmp/instantclient.zip /tmp/instantclient-sdk.zip && \
    echo /opt/oracle/instantclient_19_23 > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

# Set Oracle environment variables
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_19_23:$LD_LIBRARY_PATH \
    PATH=/opt/oracle/instantclient_19_23:$PATH

# Set working directory
WORKDIR /app

# Copy Gemfile and install dependencies
COPY Gemfile* ./
RUN gem install bundler:2.4.19 && bundle install

# Copy application code
COPY . .