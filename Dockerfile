FROM concourse/rubinius:latest

RUN gem install fresh-mc -V

CMD rbx -r fresh-mc

