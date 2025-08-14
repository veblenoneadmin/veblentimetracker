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

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /opt/kimai

# Clone Kimai (split into separate steps)
RUN git clone https://github.com/kimai/kimai.git /tmp/kimai \
    && cp -r /tmp/kimai/* . \
    && cp -r /tmp/kimai/.* . || true \
    && rm -rf /tmp/kimai

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Configure Apache
ENV APACHE_DOCUMENT_ROOT /opt/kimai/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf

# VEBLEN Environment Variables
ENV ADMINMAIL="Admin@veblengroup.com.au"
ENV ADMINPASS="VeblenKimai2024!"
ENV APP_ENV="prod"
ENV APP_SECRET="veblen_kimai_2024_railway_secure_8X9mN2pQ7wR5tE3uY1oP6iA4sD8fG9hJ0kL2mN5vB7cX3zA1qW4eR6tY9uI0pA3sD"
ENV MAILER_FROM="Admin@veblengroup.com.au"
ENV MAILER_URL="smtp://Admin@veblengroup.com.au:kaerhqzoyzmkpqhq@smtp.gmail.com:587"
ENV TRUSTED_HOSTS="localhost,127.0.0.1,*.railway.app,*.up.railway.app"

# Set permissions
RUN chown -R www-data:www-data /opt/kimai

EXPOSE 80
CMD ["apache2-foreground"]
