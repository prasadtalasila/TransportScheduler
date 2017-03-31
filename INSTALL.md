## Installation for Ubuntu 12.04/14.04/16.04:

Add Erlang Solutions repo:
```bash
wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb && sudo dpkg -i erlang-solutions_1.0_all.deb
```
Install the Erlang/OTP platform and all of its applications:
```bash
sudo apt-get update
sudo apt-get install esl-erlang
```
Install Elixir:
```bash
sudo apt-get install elixir
```

In order to get the full version number it is necessary to check the contents of the OTP_RELEASE file under the releases folder.
```bash
$ which erl
$ cd /usr/bin
$ ls -l erl
../lib/erlang/bin/erl
$ cd ../lib/erlang/
$ cat releases/17/OTP_VERSION
```
Check for OTP 19.0   

Once you have Elixir installed, you can check its version by running
```bash
elixir --version.
```
Check for Elixir > 1.3   

If you can’t install Erlang or Elixir as mentioned above or if your package manager is outdated, use `asdf` to install and manage different Elixir and Erlang versions or the Precompiled packages available.



