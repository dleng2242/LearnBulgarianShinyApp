
# Containerization Build Instructions

This file contains instructions on how to build this repository into a Docker 
image then run in a local container.

Two images are needed. The base image contains a lightweight Linux installation
with R installed along with any dependencies. The application image installs 
the Shiny app on top of this. This way, whenever changes are made to the app, 
the application image can be rebuilt without the need for re-downloading and 
installing the whole operating system and R itself, which drastically reduces 
build time.


1. Open your preferred terminal and **ensure your Docker daemon is running**.
2. Navigate to the location of your Dockerfiles - i.e. your "deploy" folder.
3. Check/Set the Dockerfile:
  * the base image name `FROM  learnbulgarianshinyapp_base:1.0`
  * the port `EXPOSE 80` - you can use any, others have used 3000.
  * the final line specifies the command to start the app
  `CMD R -e` followed by the R code. 
4. Run the following commands in your terminal in turn.

Build a base Linux image with R installed and installs any dependencies specified
within the `renv.lock.prod` file. For me this took 5 mins.
> `docker build -f Dockerfile_base --progress=plain -t learnbulgarianshinyapp_base:1.0 .`

Build a second image on top of the base image to install the shiny golem app 
from the `.tar.gz` file. 
> `docker build -f Dockerfile --progress=plain -t learnbulgarianshinyapp:1.0 .`

Run the image in a container, specify port mapping which maps localhost port 
80 to container port 80 (as defined in `EXPOSE` and `'shiny.port'=80` in the
Dockerfile).
> `docker run -d -p 80:80 --name learnbulgarianshinyapp learnbulgarianshinyapp:1.0`

5. Navigate to *127.0.0.1:80* or *localhost:80* to ensure the container is 
functioning properly and the app appears as expected.
