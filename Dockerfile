FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git curl zip unzip mariadb-client \
    libpng-dev libxml2-dev libzip-dev libicu-dev libldap2-dev libxslt1-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install pdo_mysql gd intl zip ldap xsl opcache \
    && apt-get clean \
    && a2enmod rewrite

# Configure PHP memory limit
RUN echo "memory_limit = 512M" >> /usr/local/etc/php/php.ini \
    && echo "max_execution_time = 300" >> /usr/local/etc/php/php.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /opt/kimai

# Clone Kimai
RUN git clone https://github.com/kimai/kimai.git /tmp/kimai \
    && cp -r /tmp/kimai/* . \
    && cp -r /tmp/kimai/.* . || true \
    && rm -rf /tmp/kimai

# Install dependencies with increased memory
RUN php -d memory_limit=512M /usr/bin/composer install --no-dev --optimize-autoloader --no-interaction

# Configure Apache properly
ENV APACHE_DOCUMENT_ROOT /opt/kimai/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf \
    && sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Create a proper Apache virtual host
RUN echo '<VirtualHost *:80>\n\
    DocumentRoot /opt/kimai/public\n\
    <Directory /opt/kimai/public>\n\
        AllowOverride All\n\
        Require all granted\n\
        DirectoryIndex index.php\n\
    </Directory>\n\
    <Directory /opt/kimai>\n\
        Options FollowSymlinks\n\
    </Directory>\n\
    ErrorLog ${APACHE_LOG_DIR}/error.log\n\
    CustomLog ${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>' > /etc/apache2/sites-available/000-default.conf

# VEBLEN Environment Variables
ENV ADMINMAIL="Admin@veblengroup.com.au"
ENV ADMINPASS="VeblenKimai2024!"
ENV APP_ENV="prod"
ENV APP_SECRET="veblen_kimai_2024_railway_secure_8X9mN2pQ7wR5tE3uY1oP6iA4sD8fG9hJ0kL2mN5vB7cX3zA1qW4eR6tY9uI0pA3sD"
ENV MAILER_FROM="Admin@veblengroup.com.au"
ENV MAILER_URL="smtp://Admin@veblengroup.com.au:kaerhqzoyzmkpqhq@smtp.gmail.com:587"
ENV TRUSTED_HOSTS="localhost,127.0.0.1,*.railway.app,*.up.railway.app"
ENV COMPOSER_MEMORY_LIMIT=-1

# Set proper permissions
RUN chown -R www-data:www-data /opt/kimai \
    && chmod -R 755 /opt/kimai \
    && chmod -R 777 /opt/kimai/var

# Create index.php test file in public directory
RUN echo "<?php phpinfo(); ?>" > /opt/kimai/public/test.php

EXPOSE 80
CMD ["apache2-foreground"]
