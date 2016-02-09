#!/usr/bin/env bash

# This script is executed at vagrant up to provision the VM.
# originally from https://gist.github.com/luciancancescu/57025d19da727cfdc18f#file-bootstrap_vm-sh
# changed to use process from https://gorails.com/setup/ubuntu/14.04

set -e


if [ ! -f /home/vagrant/.provisioning-progress ]; then
  su vagrant -c "touch /home/vagrant/.provisioning-progress"
  echo "--> Progress file created in /home/vagrant/.provision-progress"
  sudo apt-get update
else
  echo "--> Progress file exists in /home/vagrant/.provisioning-progress"
fi

#Set the system locale
if grep -q +locale .provisioning-progress; then
  echo "--> Locale already set, moving on."
else
  echo "--> Setting the system locale..."
  echo "LC_ALL=\"en_US.UTF-8\"" >> /etc/default/locale
  locale-gen en_US.UTF-8
  update-locale LANG=en_US.UTF-8
  su vagrant -c "echo +locale >> /home/vagrant/.provisioning-progress"
  echo "--> Locale is now set."
fi

#Install Git, Build-essential, curl, vim, htop
if grep -q +core-libs .provisioning-progress; then
  echo "--> Core libs (git, curl, etc) already installed, moving on."
else
  echo "--> Installing core libs (git, curl, etc)..."
  apt-get -y update
#  apt-get -y install build-essential curl git-core python-software-properties htop vim
#  apt-get -y install nodejs # needed by Rails to have a Javascript runtime
#  apt-get -y install zlib1g-dev libssl-dev libreadline6-dev libyaml-dev libncurses5-dev libxml2-dev libxslt-dev
  apt-get -y install git-core curl zlib1g-dev build-essential libssl-dev libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev libcurl4-openssl-dev python-software-properties libffi-dev
  su vagrant -c "echo +core-libs >> /home/vagrant/.provisioning-progress"
  echo "--> Core libs (git, curl, etc) are now installed."
fi

# Default folder to /vagrant
if grep -q +default/vagrant .provisioning-progress; then
  echo "--> default/vagrant already configured"
else
  echo "--> configuring default /vagrant"
  sudo -u vagrant printf 'cd /vagrant\n' >> /home/vagrant/.profile
  su vagrant -c "echo +default/vagrant >> /home/vagrant/.provisioning-progress"
  echo "--> default/vagrant is now configured."
fi

# Install ruby
#if grep -q +ruby/2.1.5 .provisioning-progress; then
#  echo "--> ruby-2.1.5 is installed, moving on."
#else
#  echo "--> Installing ruby-2.1.5 ..."
#  su vagrant -c "mkdir -p /home/vagrant/downloads; cd /home/vagrant/downloads; \
#                 wget --no-check-certificate https://ftp.ruby-lang.org/pub/ruby/2.1/ruby-2.1.5.tar.gz; \
#                 tar -xvf ruby-2.1.5.tar.gz; cd ruby-2.1.5; \
#                 mkdir -p /home/vagrant/ruby; \
#                 ./configure --prefix=/home/vagrant/ruby --disable-install-doc; \
#                 make; make install;"
#  sudo -u vagrant printf 'export PATH=/home/vagrant/ruby/bin:$PATH\n' >> /home/vagrant/.profile
#
#  su vagrant -c "echo +ruby/2.1.5 >> /home/vagrant/.provisioning-progress"
#  echo "--> ruby-2.1.5 is now installed."
#fi

# Install ruby via rbenv
if grep -q +ruby/2.2.3 .provisioning-progress; then
  echo "--> ruby-2.2.3 is installed, moving on."
else
  echo "--> Installing ruby-2.2.3 ..."
  su vagrant -c "cd; git clone git://github.com/sstephenson/rbenv.git ~/.rbenv"
  sudo -u vagrant echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~vagrant/.bashrc
  sudo -u vagrant echo 'eval "$(rbenv init -)"' >> ~vagrant/.bashrc

  su vagrant -c "git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build"
  sudo -u vagrant echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >> ~vagrant/.bashrc
  su vagrant -c "git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash"
  
  su vagrant -c "~/.rbenv/bin/rbenv install 2.2.3"
  su vagrant -c "~/.rbenv/bin/rbenv global 2.2.3"
  su vagrant -c "~/.rbenv/shims/ruby -v"

  su vagrant -c "echo +ruby/2.2.3 >> /home/vagrant/.provisioning-progress"
  echo "--> ruby-2.2.3 is now installed."
fi

# Install bundler
if grep -q +bundler .provisioning-progress; then
  echo "--> bundler already installed, moving on."
else
  echo "--> Installing bundler..."
  sudo -u vagrant echo "gem: --no-ri --no-rdoc" > ~vagrant/.gemrc
  su vagrant -c "~/.rbenv/shims/gem install bundler"
  su vagrant -c "echo +bundler >> /home/vagrant/.provisioning-progress"
  echo "--> +bundler is now installed."
fi

# Install rails-4.2.4
if grep -q +rails/4.2.4 .provisioning-progress; then
  echo "--> rails-4.2.4 already installed, moving on."
else
  echo "--> Installing rails-4.2.4..."
  #Install NodeJS first
  curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
  sudo apt-get -y install nodejs
  #Instal Rails now
  su vagrant -c "~/.rbenv/shims/gem install rails -v 4.2.4"
  su vagrant -c "~/.rbenv/bin/rbenv rehash"
  su vagrant -c "~/.rbenv/shims/rails -v"
  su vagrant -c "echo +rails/4.2.4 >> /home/vagrant/.provisioning-progress"
  echo "--> +rails-4.2.4 is now installed."
fi


# Install PostgreSQL
if grep -q +postgresql .provisioning-progress; then
  echo "--> postgresql already installed, moving on."
else
  echo "--> Installing postgresql..."
  sudo sh -c "echo 'deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
  wget --quiet -O - http://apt.postgresql.org/pub/repos/apt/ACCC4CF8.asc | sudo apt-key add -
  sudo apt-get update
  sudo apt-get -y install postgresql-common
  sudo apt-get -y install postgresql-9.3 libpq-dev
  #Create User
  sudo -u postgres createuser --createdb --login shine
  sudo -u postgres psql -c "ALTER USER shine WITH PASSWORD 'shine';"
  su vagrant -c "echo +postgresql >> /home/vagrant/.provisioning-progress"
  echo "--> +postgresql is now installed."
fi

# Run bundle install in the project
#if grep -q +rails_app/bundle_install .provisioning-progress; then
#  echo "--> bundle_install already ran"
#else
#  echo "--> bundle install in the project"
#  su vagrant -c "export PATH=/home/vagrant/ruby/bin:$PATH; cd /vagrant; bundle;"
#  su vagrant -c "echo +rails_app/bundle_install >> /home/vagrant/.provisioning-progress"
#  echo "--> bundle install finished."
#fi

# Setup the database + seed data + sample data
#if grep -q +rails_app/db_setup .provisioning-progress; then
#  echo "--> database already setup and seeds present"
#else
#  echo "--> setup the database + seed data + sample data"
#  su vagrant -c "export PATH=/home/vagrant/ruby/bin:$PATH; cd /vagrant; bundle exec rake db:create;"
#  su vagrant -c "export PATH=/home/vagrant/ruby/bin:$PATH; cd /vagrant; bundle exec rake db:setup;"
#  su vagrant -c "export PATH=/home/vagrant/ruby/bin:$PATH; cd /vagrant; bundle exec rake db:seed;"
#  su vagrant -c "echo +rails_app/db_setup >> /home/vagrant/.provisioning-progress"
#  echo "--> +rails_app/db_setup finished."
#fi

echo "All done"
