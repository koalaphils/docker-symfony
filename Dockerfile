FROM php:apache
LABEL description="Symfony base image" \
    version="1.0" \
    "com.koalaphils.vendor"="Koala Technologies"

RUN apt-get update \
  && apt-get install --no-install-recommends -y \
    git \
    imagemagick \
    netcat \
    libfreetype6 \
    libjpeg62-turbo \
    libpng16-16 \
    libxml2 \
    libxpm4 \
    libzip4 \
    tzdata \
    unzip \
  ;
RUN apt-get update; \
  apt-mark manual '.*' > /dev/null;\
  savedAptMark="$(apt-mark showmanual)"; \
  apt-get install -y --no-install-recommends \
    $PHPIZE_DEPS \
    gettext \
    libmagickwand-dev \
    libevent-dev \
    libfreetype6-dev \
    libicu-dev \
    libjpeg-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libssl-dev \
    libwebp-dev \
    libxml2-dev \
    libxpm-dev \
    libzip-dev \
    libbz2-dev \
    ${PHP_EXTRA_BUILD_DEPS:-} \
    ; \
  export CFLAGS="$PHP_CFLAGS" CPPFLAGS="$PHP_CPPFLAGS" LDFLAGS="$PHP_LDFLAGS" \
    ; \
  docker-php-ext-configure zip \
    --with-libzip=/usr/include \
    ; \
  docker-php-ext-configure gd \
    --with-gd \
    --with-freetype-dir=/usr/include/ \
    --with-jpeg-dir=/usr/include/ \
    --with-webp-dir=/usr/include/ \
    --with-xpm-dir=/usr/include/ \
    --with-png-dir=/usr/include/ \
  ; \
  docker-php-ext-install -j$(nproc) \
    bz2 \
    gd \
    gettext \
    intl \
    json \
    opcache \
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
  rm -rf /tmp/* ~/.pearrc /var/lib/apt/lists/*; /var/cache/* \
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

RUN curl -sS https://get.symfony.com/cli/installer | bash
RUN mv /root/.symfony/bin/symfony /usr/local/bin/symfony
COPY --from=composer /usr/bin/composer /usr/local/bin/composer
RUN git config --global user.email "admin@koalaphils.com"; \
  git config --global user.name "Koala Technologies"; \
  echo "date.timezone=Asia/Manila" > /usr/local/etc/php/conf.d/date.ini

WORKDIR /var/www/html
ONBUILD COPY app /var/www/html

ONBUILD RUN composer install --prefer-dist --no-suggest --no-interaction -ao --apcu-autoloader