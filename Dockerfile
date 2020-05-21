FROM php:apache
LABEL description="Symfony base image" \
    version="1.0" \
    "com.koalaphils.vendor"="Koala Technologies"

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    curl \
    git \
    imagemagick \
    libeditline0 \
    libjpeg62-turbo \
    libpng16-16 \
    libzip4 \
    unzip \
  ; \
  apt-mark manual '.*' > /dev/null; \
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get install -y --no-install-recommends \
    $PHPIZE_DEPS \
    gettext-base \
    libmagickwand-dev \
    libcurl4-openssl-dev \
    libicu-dev \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev \
    libwebp-dev \
    libxml2-dev \
    libzip-dev \
    libbz2-dev \
    ${PHP_EXTRA_BUILD_DEPS:-} \
    ; \
  export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
    ; \
  docker-php-ext-install -j$(nproc) \
    bz2 \
    curl \
    gd \
    gettext \
    intl \
    json \
    opcache \
    pdo_mysql \
    readline \
    session \
    simplexml \
    sodium \
    zip \
    ; \
  pecl install \
    apcu \
    igbinary \
    imagick \
    ; \
  docker-php-ext-enable \
    apcu \
    igbinary \
    imagick \
    intl \
    opcache \
    ; \
  cp /usr/bin/envsubst /usr/local/bin/envsubst; \
  apt-mark auto '.*' > /dev/null; \
  [ -z "$savedAptMark" ] || apt-mark manual $savedAptMark; \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImport=false; \
  rm -rf /tmp/* ~/.pearrc /var/lib/apt/lists/* /var/cache/*; \
  php --version; \
  a2enmod \
    brotli \
    buffer \
    cache \
    expires \
    headers \
    mime_magic \
    remoteip \
    rewrite \
  ;

COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN sed -i "s|/var/www/html|/var/www/html/public|g" /etc/apache2/sites-enabled/000-default.conf

WORKDIR /var/www/html

RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony/bin/symfony /usr/local/bin/symfony

ONBUILD COPY app /var/www/html
ONBUILD RUN composer config --global use-github-api false; \
  composer config --global vendor-dir /var/www/vendor; \ 
  ln -s /var/www/vendor /var/www/html/vendor; \
  composer install --prefer-dist --no-suggest --no-interaction -ao --apcu-autoloader \
  ;
