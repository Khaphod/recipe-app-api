FROM python:3.9-alpine3.13

#the author/maintainer -- this is optional
LABEL maintainer="me_myself"

#you don't want to buffer the output
#the output will be printed directly to the console
#which prevents any delays of messages
ENV PYTHONUNBUFFERED 1 

#copy local "requirements.txt" to "/tmp/"
#which is inside the container
COPY ./requirements.txt /tmp/requirements.txt
COPY ./requirements.dev.txt /tmp/requirements.dev.txt
#copy local "app" (Django Application) to "/app"
#which is inside the container
COPY ./app /app

#it's the default directory that our commands
#are going to be run from when we run them 
#on our Docker image
WORKDIR /app

#exposing port 8000 from our container to our
#machine when running it
#this way we can connect to the Django Dev. Server
EXPOSE 8000


#We set it to False, then the docker-compose overrides it to True
#When we use it in any other Docker compose config, it's going to
#leave it as false
ARG DEV=false 



#runs a command on the Alpine image that we are using
# 1) Create a Python virtual environment (best practice)
    ## it can avoid Python dependencies conflicts between
    ## the actual base image and your project dependencies

# 2) Inside the virtual environm. runs:
    ## 2.1) pip install --upgrade pip
    ## 2.2) pip install -r /tmp/requirements.txt

# 3) Removes the '/tmp' directory because we don't need it
# anymore as we already installed the dependencies from 
# requirements.txt

# 4) It's best practice not to use the root user, so:
    ## 4.1) we disable password entry necessity as we don't want
    ##      anyone to be able to gain root permission.
    ## 4.2) we don't create a '/home' directory: keeps the docker
    ##      image light as possible

    ## 4.3) we just specify the name of the user

RUN python -m venv /py && \ 
    /py/bin/pip install --upgrade pip && \
    apk add --update --no-cache postgresql-client && \
    apk add --update --no-cache --virtual .tmp-build-deps \
        build-base postgresql-dev musl-dev && \
    /py/bin/pip install -r /tmp/requirements.txt && \
    if [ $DEV = "true" ]; \
        then /py/bin/pip install -r /tmp/requirements.dev.txt ; \
    fi && \
    rm -rf /tmp && \
    apk del .tmp-build-deps && \
    adduser \
        --disabled-password \
        --no-create-home \
        django-user


# updates the env. variable inside the image 
# we are updating the path env. variable;
# the path is the env. variable that's automatically created
# on Linux OS

# ---- WHY IS THIS USEFUL? ----
# It defines all of the directories where executables can be run.
# So when we run any command in our project, we don't want to 
# specify the full path of our VENV everytime..
# Then we add the "/py/bin" path to the system path, so when we
# run any Python commands, it will run automatically FROM our VENV
ENV PATH="/py/bin:$PATH"


# switching from root user to the 'django-user' we defined
#USER django-user