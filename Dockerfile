FROM rubinius/docker:latest

ENV SSL_CERT_FILE=/etc/ssl/cetts/cacert.pem 

RUN apt-get -y install wget

RUN wget -O $SSL_CERT_FILE http://curl.haxx.se/ca/cacert.pem

RUN rbx -S gem install fresh-mc --no-rdoc --no-ri -V

CMD rbx -r fresh-mc

