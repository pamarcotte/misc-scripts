#!/bin/bash

NGINX_CUR="$(curl -s "http://nginx.org/download/"|grep -oP "nginx-[0-9\.?]+\.tar\.gz"|tail -1|sed "s/.tar.gz//")"
NGINX_DLURL="http://nginx.org/download/${NGINX_CUR}.tar.gz"
NGINX_TAR="$(basename ${NGINX_DLURL})"
NGINX_BASE="$(basename ${NGINX_CUR})"

# Install nginx to /usr/local/nginx/
install_nginx() {
	echo "Downloading Nginx"
	wget --quiet "${NGINX_DLURL}"
	[[ ! -f ${NGINX_TAR} ]] && { echo "Couldn't find ${NGINX_TAR}. Exiting."; exit 1; }
	echo "Unpacking Nginx"
	tar -xzf ${NGINX_TAR}
	cd ${NGINX_BASE}
	echo "Configure, make, make install"
	./configure 	--prefix=/usr/local/nginx \
			--sbin-path=/usr/bin/nginx \
			--conf-path=/usr/local/nginx/nginx.conf \
			--http-client-body-temp-path=/var/cache/nginx/client_body_temp \
			--http-proxy-temp-path=/var/cache/nginx/proxy_temp_path \
			--http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp_path \
			--http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp_path \
			--http-scgi-temp-path=/var/cache/nginx/scgi_temp_path \
			--error-log-path=/var/log/nginx/nginx.log \
			--http-log-path=/var/log/nginx/access.log \
			--pid-path=/var/run/nginx/nginx.pid \
			--lock-path=/var/lock/subsys/nginx \
			--user=nginx \
			--group=nginx \
			--with-select_module \
			--with-poll_module \
			--with-http_ssl_module \
			--with-http_realip_module \
			--with-http_addition_module \
			--with-http_xslt_module \
			--with-http_image_filter_module \
			--with-http_sub_module \
			--with-http_dav_module \
			--with-http_flv_module \
			--with-http_mp4_module \
			--with-http_gunzip_module \
			--with-http_gzip_static_module \
			--with-http_auth_request_module \
			--with-http_degradation_module \
			--with-http_stub_status_module \
			--without-mail_pop3_module \
			--without-mail_imap_module \
			--without-mail_smtp_module && make && make install
}

# Compare latest version with our own version that's installed
check_version() {
	NGINX_INSTALLED="$(/usr/bin/nginx -V 2>&1|grep -oP "nginx\/[0-9\.?]+"|sed "s/\//-/")"
	[[ ! ${NGINX_INSTALLED} == ${NGINX_CUR} ]] && echo "New version available - ${NGINX_CUR}"
}

if [[ ${1} == "version" ]]; then
	check_version
elif [[ ${1} == "install" ]]; then
	install_nginx
else
	echo -e "Two options available:\n\t${0} install\n\t${0} version"
fi

