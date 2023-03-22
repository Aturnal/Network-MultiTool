FROM alpine:3.15

EXPOSE 22 80 443 1180 11443

# Install some tools in the container and generate self-signed SSL certificates.
# Packages are listed in alphabetical order, for ease of readability and ease of maintenance.
RUN     apk update \
    &&  apk add dropbear bash bind-tools busybox-extras curl \
                iproute2 iputils jq mtr \
                net-tools nginx openssl \
                perl-net-telnet procps tcpdump tcptraceroute wget \
    &&  mkdir /certs /docker \
    &&  chmod 700 /certs \
    &&  openssl req \
        -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout /certs/server.key -out /certs/server.crt -subj '/CN=localhost'

###
# set a password to SSH into the docker container with
RUN echo 'root:alpine' | chpasswd
###

# Copy a simple index.html to eliminate text (index.html) noise which comes with default nginx image.
# (I created an issue for this purpose here: https://github.com/nginxinc/docker-nginx/issues/234)

COPY index.html /usr/share/nginx/html/


# Copy a custom/simple nginx.conf which contains directives
#   to redirected access_log and error_log to stdout and stderr.
# Note: Don't use '/etc/nginx/conf.d/' directory for nginx virtual hosts anymore.
#   This 'include' will be moved to the root context in Alpine 3.14.

COPY nginx.conf /etc/nginx/nginx.conf

COPY entrypoint.sh /docker/entrypoint.sh


# Start nginx in foreground (pass CMD to docker entrypoint.sh):
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]



# Note: If you have not included the "bash" package, then it is "mandatory" to add "/bin/sh"
#         in the ENTNRYPOINT instruction. 
#       Otherwise you will get strange errors when you try to run the container. 
#       Such as:
#       standard_init_linux.go:219: exec user process caused: no such file or directory

# Run the startup script as ENTRYPOINT, which does few things and then starts nginx.
ENTRYPOINT ["/bin/sh", "/docker/entrypoint.sh"]





###################################################################################################

# Build in local docker environment (for testing) instructions:
# -------------------------------------------
# docker build -t local/network-multitool .
# docker run --name test_multitool_sshd -d local/network-multitool
# docker exec -it test_multitool_sshd /bin/bash
# or
# ssh admin@172.17.0.2 #IP address may/will vary in your environment


# Pushing to GHCR
# -------------------------------------------
# docker build -t local/network-multitool .
# export CR_PAT=YOUR_TOKEN <PAT Generated from github UI>
# echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
# # await > Login Succeeded
# docker push ghcr.io/aturnal/network-multitool:latest
# docker push aturnal/network-multitool


# Pull (from ghcr):
# ----------------------
# docker pull ghcr.io/aturnal/network-multitool


# Usage - on Docker:
# ------------------
# docker run --rm -it aturnal/network-multitool /bin/bash 
# OR
# docker run -d  aturnal/network-multitool
# OR
# docker run -p 22:22 -p 80:80 -p 443:443 -d  aturnal/network-multitool
# OR
# docker run -e SSH_PORT=22 -e HTTP_PORT=1180 -e HTTPS_PORT=11443 -p 1180:1180 -p 11443:11443 -d  aturnal/network-multitool


# Usage - on Kubernetes:
# ---------------------
# kubectl run multitool --image=aturnal/network-multitool
