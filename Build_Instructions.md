
# Build Instructions

This file contains instructions on how to build this repository into a Docker 
image then run in a local container.

Two images are needed. The base image contains a lightweight Linux installation
with R installed along with any dependencies. The application image installs 
the Shiny app on top of this. This way, whenever changes are made to the app, 
the application image can be rebuilt without the need for re-downloading and 
installing the whole operating system and R itself, which drastically reduces 
build time.


1. Open your preferred terminal and ensure Docker is working. 
2. Navigate to the location of your Dockerfiles - i.e. your "deploy" folder.
3. Change/check the following in the Dockerfile:
  * Line 1: `FROM  learnbulgarianshinyapp_base:0.1` - update the version tag
  * Line 2: `COPY renv.lock renv.lock` - check the first ".lock" matches yours
  * Line 7: `EXPOSE 80` - note/change port, others have used 3000
  * Line 8: `CMD R -e "options('shiny.port'=80 ...` - check port matches
4. Run the following commands in your terminal in turn.

Build a base Linux image with R installed and installs any dependencies specified
within the `renv.lock` file. For me this took 5 mins.
> `docker build -f Dockerfile_base --progress=plain -t learnbulgarianshinyapp_base:0.1 .`

Build a second image on top of the base image to install the shiny golem app 
from the `.tar.gz` file. 
> `docker build -f Dockerfile --progress=plain -t learnbulgarianshinyapp:0.1 .`

Run the image in a container, specifying the port mapping defined in the 
Dockerfile. Here we map localhost port 80 to container port 80.
> `docker run -d -p 80:80 --name learnbulgarianshinyapp learnbulgarianshinyapp:0.1`

5. Navigate to *127.0.0.1:80* or *localhost:80* to ensure the container is 
functioning properly and the app appears as expected.


### Possible Issues

Golem assumes a standard rocker base image, but if you have other dependencies it might be better to manually set a different image, such as the rocker/geospatial that has geospatial system dependencies already installed.  If you do this you might also need to then tell Docker to install Shiny Server too. More info [here](https://rocker-project.org/images/). 

I had to manually update my base image name, tags, and my renv.lock file so double check yours match. 
