#!/bin/bash
STARTTIME=`date +'%Y%m%dT%H%M%S'`
OUTPUTDIR=./output_$STARTTIME

if [ -d "../git" ]; then
  echo [`date +'%Y%m%dT%H%M%S'`] Updating local git repository.
  git pull
fi

# XX don't recreate this every time?!
docker build .. -f Dockerfile -t ffmpeg-windows-build-helpers-image # builds an image

if [ $? -eq 0 ]; then
    ## TODO make better so it doe snot clone everytime, but also no nested repositories. .dockerignore and self copy should also work.
    #rm -rf ./ffmpeg-windows-build-helpers

    mkdir -p $OUTPUTDIR
    echo [`date +'%Y%m%dT%H%M%S'`] Creating and starting container...
    # When rerunning use $ docker start ffmpegbuilder -i, then in other terminal $ docker exec -it ffmpegbuilder touch /tmp/loop; docker exec -it ffmpegbuilder /bin/bash
    # while the first is still running...
    docker run --name ffmpegbuilder -it ffmpeg-windows-build-helpers-image || docker start ffmpegbuilder -i

    if [ $? -eq 0 ]; then
        echo [`date +'%Y%m%dT%H%M%S'`] Build successful
        echo [`date +'%Y%m%dT%H%M%S'`] Extracting build artefacts...
        docker cp ffmpegbuilder:/output/static/ $OUTPUTDIR

        if [ $? -eq 0 ]; then
            echo [`date +'%Y%m%dT%H%M%S'`] Static extraction successful. Started: $STARTTIME
        else
            echo [`date +'%Y%m%dT%H%M%S'`] Static extraction failed. Started: $STARTTIME
        fi

        docker cp ffmpegbuilder:/output/shared/ $OUTPUTDIR

        if [ $? -eq 0 ]; then
            echo [`date +'%Y%m%dT%H%M%S'`] Shared extraction successful. Started: $STARTTIME
        else
            echo [`date +'%Y%m%dT%H%M%S'`] Shared extraction failed. Started: $STARTTIME
        fi
        
    else
        echo [`date +'%Y%m%dT%H%M%S'`] Build failed. Started: $STARTTIME
    fi
    echo [`date +'%Y%m%dT%H%M%S'`] Stopping container...
    docker stop ffmpegbuilder # this should never be needed tho?
    # Comment this if you want to keep your sandbox data and rerun the container at a later time.
    # echo [`date +'%Y%m%dT%H%M%S'`] Removing container...
    # docker rm ffmpegbuilder
    echo 'done'
else
    echo [`date +'%Y%m%dT%H%M%S'`] Docker build failed. Started: $STARTTIME
    exit 1
fi
