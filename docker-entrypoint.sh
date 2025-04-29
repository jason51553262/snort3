#!/bin/bash

# Start the app with unbuffered output
stdbuf -oL -eL snort $@