FROM rubinius/docker:latest

RUN gem install fresh-mc -V

CMD rbx -r fresh-mc

