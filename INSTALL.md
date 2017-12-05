## Installation for Ubuntu 12.04/14.04/16.04:

Install dependencies for Erlang OTP/19.0
```bash
sudo add-apt-repository ppa:nilarimogard/webupd8
sudo apt-get update
sudo apt-get install libwxbase2.8-0 libwxgtk2.8-0
```

Add Erlang Solutions repo:
```bash
wget https://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_19.0-1~ubuntu~xenial_amd64.deb
sudo dpkg -i esl-erlang_19.0-1~ubuntu~xenial_amd64.deb
```

Install Elixir:
```bash
sudo apt-get install elixir
```

In order to get the full version number it is necessary to check the contents of the OTP_RELEASE file under the releases folder.
```bash
which erl     #probably /usr/bin/erl
cd /usr/bin
ls -l erl     #probably ../lib/erlang/bin/erl
cd ../lib/erlang/
cat releases/19/OTP_VERSION
```
Check for OTP 19.0.   

Once you have Elixir installed, you can check its version by running:
```bash
elixir --version.
```
Check for Elixir above 1.3.   

If you can’t install Erlang or Elixir as mentioned above or if your package manager is outdated, use [asdf](https://github.com/asdf-vm/asdf) to install and manage different Elixir and Erlang versions or the Precompiled packages available.
