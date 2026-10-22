FROM nginx:alpine
ARG FAULTY=false
COPY index.html /usr/share/nginx/html/index.html
RUN if [ "$FAULTY" = "true" ]; then echo "invalid_directive on;" > /etc/nginx/conf.d/default.conf; fi
EXPOSE 80