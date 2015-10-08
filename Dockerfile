FROM ubuntu:14.04
MAINTAINER Andreas Nanko <andreas@opstack.io>

# Keep upstart from complaining
RUN dpkg-divert --local --rename --add /sbin/initctl
RUN ln -sf /bin/true /sbin/initctl

# Environment
ENV HOME /root
ENV DEBIAN_FRONTEND noninteractive

# Install software packages
RUN apt-get -y update && apt-get install -y openssh-server nginx php5-fpm php5-cli php5-mysql php5-gd php5-curl mysql-server supervisor git 

# Set root password
RUN echo 'root:needstobefixed' | chpasswd
# Enable root ssh login
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# Create sshd directory
RUN mkdir /var/run/sshd

# mysql config
RUN sed -i -e"s/^bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# nginx config
RUN sed -i -e"s/keepalive_timeout\s*65/keepalive_timeout 2/" /etc/nginx/nginx.conf
RUN sed -i -e"s/keepalive_timeout 2/keepalive_timeout 2;\n\tclient_max_body_size 100m/" /etc/nginx/nginx.conf
RUN echo "daemon off;" >> /etc/nginx/nginx.conf
RUN rm /etc/nginx/sites-enabled/default
COPY nginx/fastcgi_params.oxid /etc/nginx/
COPY nginx/oxid.conf /etc/nginx/sites-enabled/oxid.conf


# php-fpm config
RUN sed -i -e "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/upload_max_filesize\s*=\s*2M/upload_max_filesize = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/post_max_size\s*=\s*8M/post_max_size = 100M/g" /etc/php5/fpm/php.ini
RUN sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf
RUN sed -i -e "s/;catch_workers_output\s*=\s*yes/catch_workers_output = yes/g" /etc/php5/fpm/pool.d/www.conf
RUN sed -i -e "s/listen\s*=\s*\/var\/run\/php5-fpm.sock/listen = 127.0.0.1:9000/g" /etc/php5/fpm/pool.d/www.conf
RUN find /etc/php5/cli/conf.d/ -name "*.ini" -exec sed -i -re 's/^(\s*)#(.*)/\1;\2/g' {} \;

# supervisord config
COPY supervisord/conf.d/sshd.conf /etc/supervisor/conf.d/sshd.conf
COPY supervisord/conf.d/php-fpm.conf /etc/supervisor/conf.d/php-fpm.conf
COPY supervisord/conf.d/nginx.conf /etc/supervisor/conf.d/nginx.conf
COPY supervisord/conf.d/mysql.conf /etc/supervisor/conf.d/mysql.conf

# Bootstrap Oxid
RUN mkdir -p /data/www/oxid
RUN cd /data/www/oxid && git clone https://github.com/OXID-eSales/oxideshop_ce.git
RUN mv /data/www/oxid/oxideshop_ce/source /data/www/oxid/public
RUN rm -rf /data/www/oxid/oxideshop_ce
RUN chown -R www-data:www-data /data/www/oxid/public

# Execute supervisord
CMD /usr/bin/supervisord -n
