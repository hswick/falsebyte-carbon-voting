**On ubuntu Only**

Make sure your system is up-to-date:

`apt-get update`  
`apt-get upgrade`

**On Mac or Linux**

Install required build tools   

`sudo apt install build-essential git cmake python python-dev libcurl3-dev`

Install cmake using the instructions here: [https://cmake.org/download/](https://cmake.org/download/)

Install git using these instructions: [https://git-scm.com/download/mac](https://git-scm.com/download/mac)

Download quickBlocks

`git install -b develop http://github.com/Great-Hill-Corporation/quickBlocks`

Then

`cd quickBlocks`  
`mkdir build`  
`cmake ../src`  
`make`  
`sudo make install`  