FROM jenkins/jenkins:2.150.3

# set timezone for Java runtime arguments #TODO: FIXME security vulnerability
ENV JAVA_OPTS='-Duser.timezone=Asia/Shanghai -Dpermissive-script-security.enabled=no_security'

# set timezone for OS by root
USER root
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

# docker のバイナリをinstall
RUN wget https://download.docker.com/linux/static/stable/x86_64/docker-18.03.1-ce.tgz
RUN tar -xvf docker-18.03.1-ce.tgz
RUN mv docker/* /usr/bin/

# jenkins userでもdockerが使えるようにする
RUN groupadd -o -g ${DOCKER_GROUP_GID} docker
RUN usermod -g docker jenkins

# Plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Local Plugins
COPY hpi/* /usr/share/jenkins/ref/plugins/

# install Maven
USER root
RUN sed -i "s@http://deb.debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list
RUN sed -i "s@http://security.debian.org@http://mirrors.aliyun.com@g" /etc/apt/sources.list

RUN apt-get update && apt-get install -y maven vim

RUN update-ca-certificates --fresh

# Add vault + consul-template descriped in https://ifritltd.com/2018/03/18/advanced-jenkins-setup-creating-jenkins-configuration-as-code-and-applying-changes-without-downtime-with-java-groovy-docker-vault-consul-template-and-jenkins-job/
RUN curl https://raw.githubusercontent.com/georgedriver/devops-tools/master/vault_1.0.3_linux_amd64.zip -o vault_1.0.3_linux_amd64.zip

RUN unzip vault_1.0.3_linux_amd64.zip -d /usr/local/bin/ && rm -fr vault_1.0.3_linux_amd64.zip

RUN curl https://raw.githubusercontent.com/georgedriver/devops-tools/master/consul-template?raw=true -o consul-template

RUN mv consul-template /usr/local/bin/ && rm -fr consul-template

RUN chmod 775 /usr/local/bin/consul-template

# Init scripts
COPY script/ /usr/share/jenkins/ref/init.groovy.d/
RUN chown jenkins:jenkins -R /usr/share/jenkins/ref/init.groovy.d/

USER jenkins
