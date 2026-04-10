# Scripts
This directory contains various utility scripts to assist with the setup and management of the system, such as generating configuration files and automating tasks, etc. It is the central location for scripts that help streamline development and deployment processes.

TODO: explain project directory, such as load_config.sh to load general configuration, lib.sh for all shared functions.
TODO: add decided NOT to add a main.sh in the root since it is hard and unnecessary to call scripts from there, you can just source the load_config.sh in the script you want to run, and then call the functions you need. This keeps things simple and avoids unnecessary indirection. For example, deciding the arguments a script takes from main.sh is hard and unnecessarily complex.