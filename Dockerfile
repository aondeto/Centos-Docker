FROM centos:latest

MAINTAINER Vinicius Chaves (vchaves@aonde.to)


# Install EPEL
RUN yum install -y epel-release && yum clean all

# Update RPM Packages
RUN yum -y update && yum clean all

#Install Packages (WGET TAR GCC VIM )
RUN yum install -y wget tar gcc vim openssh-server openssh-clients sudo && yum clean all

#Install Packages (Supervisor)
RUN yum --enablerepo=epel install -y supervisor &&  yum clean all

# set timezone (Sao_Paulo)
RUN rm -f /etc/localtime
RUN ln -s /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Create User appuser
RUN useradd -g wheel appuser
RUN echo 'appuser:appuser' | chpasswd

# Config SSH
# Change password for user root
RUN echo 'root:root' | chpasswd
# No direct ROOT login
#RUN sed -i -e 's/^\(PermitRootLogin\s\+.\+\)/#\1/gi' /etc/ssh/sshd_config
#RUN echo -e '\nPermitRootLogin no' >> /etc/ssh/sshd_config
# make ssh directories
RUN mkdir /root/.ssh
RUN mkdir /var/run/sshd
RUN mkdir /home/appuser/.ssh
# create host keys
RUN ssh-keygen -b 1024 -t rsa -f /etc/ssh/ssh_host_key
RUN ssh-keygen -b 1024 -t rsa -f /etc/ssh/ssh_host_rsa_key
RUN ssh-keygen -b 1024 -t dsa -f /etc/ssh/ssh_host_dsa_key
# move public key to enable ssh keys login
ADD docker_ssh.pub /root/.ssh/authorized_keys
RUN chmod 400 /root/.ssh/authorized_keys
RUN chown root:root /root/.ssh/authorized_keys
# tell ssh to not use ugly PAM
RUN sed -i 's/UsePAM\syes/UsePAM no/' /etc/ssh/sshd_config
# Expose Porta 22
EXPOSE 22

# Config Network
# enable networking
RUN echo 'NETWORKING=yes' >> /etc/sysconfig/network

#Config Sudo
RUN sed -i -e 's/^\(%wheel\s\+.\+\)/#\1/gi' /etc/sudoers
RUN echo -e '\n%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
RUN echo -e '\nDefaults:root   !requiretty' >> /etc/sudoers
RUN echo -e '\nDefaults:%wheel !requiretty' >> /etc/sudoers


# Config Vim
# for root
RUN echo 'syntax on'      >> /root/.vimrc
RUN echo 'alias vi="vim"' >> /root/.bash_profile
# for appuser
RUN echo 'syntax on'      >> /home/appuser/.vimrc
RUN echo 'alias vi="vim"' >> /home/appuser/.bash_profile



# Config Supervisor
ADD supervisord.conf /etc/
RUN chmod 600 /etc/supervisord.conf /etc/supervisord.d/*.ini

#Start Supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
