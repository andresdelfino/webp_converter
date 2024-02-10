#!/bin/bash
docker run -ti --rm=true --mount type=bind,source=$HOME/Downloads/webp,destination=/channel webp_converter