# The default Docker image
ARG IMAGE_BASE_NAME
ARG BASE_IMAGE_HASH
ARG BASE_BUILDER_IMAGE_HASH

FROM ${IMAGE_BASE_NAME}:base-builder-${BASE_BUILDER_IMAGE_HASH} as builder
# copy files
COPY . /build/

# change working directory
WORKDIR /build

# install dependencies
RUN python -m venv /opt/venv
RUN . /opt/venv/bin/activate

RUN pip install --no-cache-dir -U 'pip<20' 
RUN poetry install --no-dev --no-root --no-interaction 
RUN poetry build -f wheel -n
RUN pip install --no-deps dist/*.whl
RUN rm -rf dist *.egg-info

# start a new build stage
FROM ${IMAGE_BASE_NAME}:base-${BASE_IMAGE_HASH} as runner

# copy everything from /opt
COPY --from=builder /opt/venv /opt/venv

# make sure we use the virtualenv
ENV PATH="/opt/venv/bin:$PATH"

# update permissions & change user to not run as root
WORKDIR /app
RUN chgrp -R 0 /app && chmod -R g=u /app
USER 1001

# create a volume for temporary data
VOLUME /tmp

# change shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# the entry point
EXPOSE 5005
ENTRYPOINT ["rasa"]
CMD ["--help"]
