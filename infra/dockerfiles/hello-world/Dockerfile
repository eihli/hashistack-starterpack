FROM busybox:latest

RUN echo "Hello, world!" >> /var/www/index.html

CMD httpd -f -p 8888 -h /var/www
