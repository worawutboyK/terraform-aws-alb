FROM ubuntu
# TODO: try to switch to this https://github.com/holms/docker-rvm-alpine
# TODO: integrate into travis CI

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:rael-gc/rvm && \
    apt-get update -y && \
    apt-get install rvm -y && \
    /bin/bash -l -c "rvm install 2.4.2 && \
    echo 'gem: --no-ri --no-doc' > ~/.gemrc && \
    gem install bundler --no-rdoc --no-ri"

RUN apt-get install -y unzip wget git && \
    wget https://releases.hashicorp.com/terraform/0.11.8/terraform_0.11.8_linux_amd64.zip && \
    # TODO verify md5sum == '84ccfb8e13b5fce63051294f787885b76a1fedef6bdbecf51c5e586c9e20c9b7' && \
    unzip terraform_0.11.8_linux_amd64.zip && \
    mv terraform /usr/local/bin/

#XXX install awscli?


COPY Gemfile ./
RUN /bin/bash -l -c "bundle install"
ENV WORKDIR /root/static
WORKDIR ${WORKDIR}
COPY . .

RUN echo "alias tf_test=\"/bin/bash -l -c 'bundle exec kitchen list'\"" >> /root/.bashrc

# as an alternative, copy the ~/.aws/credentials file and ~/.aws/config file to the container

ENV AWS_ACCESS_KEY_ID ${AWS_ACCESS_KEY_ID}
ENV AWS_SECRET_ACCESS_KEY ${AWS_SECRET_ACCESS_KEY}
ENV AWS_SESSION_TOKEN ${AWS_SESSION_TOKEN}

RUN mkdir -p ~/.ssh && \
    echo "Host *\n  StrictHostKeyChecking no\n" > ~/.ssh/config && \
    chmod 400 ~/.ssh/config

# TODO: run terraform as a container IN this container instead of downloading
# docker run -v /var/run/docker.sock:/var/run/docker.sock \
#            -ti docker

RUN /bin/bash -l -c 'bundle exec kitchen create && bundle exec kitchen test --destroy always'

# ENTRYPOINT ["/root/static/docker-entrypoint.sh"]
ENTRYPOINT ["/bin/bash"]
