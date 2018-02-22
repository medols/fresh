FROM rubinius/docker:latest

RUN rbx -S gem install fresh-mc --no-rdoc --no-ri -V

CMD rbx -r fresh-mc

