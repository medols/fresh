FROM rubinius/docker:latest

RUN gem install fresh-mc --no-rdoc --no-ri -V

CMD rbx -r fresh-mc

